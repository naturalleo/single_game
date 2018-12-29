require "utils/functions"
local CreateCardUtil = class("CreateCardUtil")
local Card = require("logic.Card")
local CardPattern = require("logic.CardPattern")
local lordSingleConfig = require('single_game.SingleGameConfig')
local log_util = require("utils.log_util")
local TAG = "CreateCardUtil"

local allCards_ = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
    32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53}
-- 由牌值分组
local allCardsValue_ = {
    {0, 13, 26, 39},
    {1, 14, 27, 40},
    {2, 15, 28, 41},
    {3, 16, 29, 42},
    {4, 17, 30, 43},
    {5, 18, 31, 44},
    {6, 19, 32, 45},
    {7, 20, 33, 46},
    {8, 21, 34, 47},
    {9, 22, 35, 48},
    {10, 23, 36, 49},
    {11, 24, 37, 50},
    {12, 25, 38, 51},
    {52, 53}
}
local TOTAL_CARD_COUNT = 54
local BOTTOM_CARD_COUNT = 3
local PLAYER_COUNT = 3

local SPECIAL_CARD_SINGLE = 1
local SPECIAL_CARD_DOUBLE = 2
local SPECIAL_CARD_STRAIGHT = 3
local SPECIAL_CARD_BOMB = 4

local doubleCardsCountRange = {min = 4, max = 5}
local singleCardsCountRange = {min = 4, max = 4}
local straightLengthRange = {min = 5, max = 12}
local bombCardsCountRange = {min = 1, max = 1}

local cardValue_ = {
    CARD_POINT_3 = 3,
    CARD_POINT_4 = 4,
    CARD_POINT_5 = 5,
    CARD_POINT_6 = 6,
    CARD_POINT_7 = 7,
    CARD_POINT_8 = 8,
    CARD_POINT_9 = 9,
    CARD_POINT_10 = 10,
    CARD_POINT_J = 11,
    CARD_POINT_Q = 12,
    CARD_POINT_K = 13,
    CARD_POINT_A = 14,
    CARD_POINT_2 = 15,
    CARD_POINT_LITTLE_JOKER = 16,
    CARD_POINT_BIG_JOKER = 17
}

local NPC_SPECIAL_CARD_PERCENT = {
	-- 下标与牌型ID一致
	-- 豆豆
	{
		{min = 1, max = 20},
		{min = 21, max = 50},
		{min = 51, max = 65},
		{min = 66, max = 73},
		{min = 74, max = 78},
		{min = 79, max = 85},
		{min = 86, max = 90},
		{min = 91, max = 100},
	},
	-- 孙叔
	{
		{min = 1, max = 40},
		{min = 41, max = 60},
		{min = 61, max = 65},
		{min = 66, max = 70},
		{min = 71, max = 75},
		{min = 76, max = 80},
		{min = 81, max = 90},
		{min = 91, max = 100},
	},
	-- 赵婶
	{
		{min = 1, max = 60},
		{min = 61, max = 75},
		{min = 76, max = 80},
		{min = 81, max = 85},
		{min = 0, max = 0},
		{min = 86, max = 90},
		{min = 91, max = 95},
		{min = 96, max = 100},
	},
	-- 大老刘
	{
		{min = 1, max = 80},
		{min = 81, max = 85},
		{min = 0, max = 0},
		{min = 86, max = 90},
		{min = 0, max = 0},
		{min = 91, max = 95},
		{min = 96, max = 100},
		{min = 0, max = 0},
	},
}

local MIN_CARD_POINT = 8
-- 牌型权值
local RANDOM_CARD_TYPE_POINT = {
	{cardMinValue = cardValue_.CARD_POINT_BIG_JOKER, cardMaxValue = cardValue_.CARD_POINT_BIG_JOKER, maxCount = 0, point = 5},
	{cardMinValue = cardValue_.CARD_POINT_LITTLE_JOKER, cardMaxValue = cardValue_.CARD_POINT_LITTLE_JOKER, maxCount = 0, point = 3},
	{cardMinValue = cardValue_.CARD_POINT_2, cardMaxValue = cardValue_.CARD_POINT_2, maxCount = 4, point = 2},
	{cardMinValue = cardValue_.CARD_POINT_A, cardMaxValue = cardValue_.CARD_POINT_A, maxCount = 4, point = 1},
	{cardMinValue = cardValue_.CARD_POINT_10, cardMaxValue = cardValue_.CARD_POINT_K, maxCount = 0, point = 5}, -- 10-K的炸弹
	{cardMinValue = cardValue_.CARD_POINT_3, cardMaxValue = cardValue_.CARD_POINT_9, maxCount = 0, point = 4}, -- 3-9的炸弹
}

-- 强控牌型中大小王与2的几率
local CONTROL_CARD_TYPE_PERCENT = {
	{bigJokerCount = 1, littleJokerCount = 0, card2Count = 2, minPercent = 1, maxPercent = 15},
	{bigJokerCount = 1, littleJokerCount = 0, card2Count = 3, minPercent = 16, maxPercent = 25},
	{bigJokerCount = 1, littleJokerCount = 0, card2Count = 4, minPercent = 26, maxPercent = 30},
	{bigJokerCount = 0, littleJokerCount = 1, card2Count = 2, minPercent = 31, maxPercent = 45},
	{bigJokerCount = 0, littleJokerCount = 1, card2Count = 3, minPercent = 45, maxPercent = 60},
	{bigJokerCount = 0, littleJokerCount = 1, card2Count = 4, minPercent = 61, maxPercent = 65},
	{bigJokerCount = 1, littleJokerCount = 1, card2Count = 1, minPercent = 66, maxPercent = 75},
	{bigJokerCount = 1, littleJokerCount = 1, card2Count = 2, minPercent = 76, maxPercent = 90},
	{bigJokerCount = 1, littleJokerCount = 1, card2Count = 3, minPercent = 91, maxPercent = 96},
	{bigJokerCount = 1, littleJokerCount = 1, card2Count = 4, minPercent = 97, maxPercent = 100},
}

local BOMB_CARD_COUNT_PERCENT = {
	{count = 1, minPercent = 1, maxPercent = 73},
	{count = 2, minPercent = 74, maxPercent = 93},
	{count = 3, minPercent = 94, maxPercent = 100},
}

local THREE_CARD_COUNT_PERCENT = {
	{count = 1, minPercent = 1, maxPercent = 15},
	{count = 2, minPercent = 16, maxPercent = 55},
	{count = 3, minPercent = 56, maxPercent = 95},
	{count = 4, minPercent = 96, maxPercent = 98},
	{count = 5, minPercent = 99, maxPercent = 100},
}

-- baseCardCount: 1：单顺，2：双顺， 3：三顺
-- strightMinLength: 顺子的最小长度
-- strightMaxLength: 顺子的最大长度
local SPLIT_CARD_TYPE_PERCENT = {
    {strightMinLength = 6, strightMaxLength = 12, baseCardCount = 1, percentMin = 1, percentMax = 25},
    {strightMinLength = 5, strightMaxLength = 5, baseCardCount = 2, percentMin = 26, percentMax = 55},
    {strightMinLength = 3, strightMaxLength = 3, baseCardCount = 2, percentMin = 56, percentMax = 75},
    {strightMinLength = 4, strightMaxLength = 4, baseCardCount = 2, percentMin = 76, percentMax = 85},
    {strightMinLength = 5, strightMaxLength = 5, baseCardCount = 2, percentMin = 86, percentMax = 90},
    {strightMinLength = 2, strightMaxLength = 2, baseCardCount = 3, percentMin = 91, percentMax = 100}
}

CreateCardUtil.allCards_ = nil
CreateCardUtil.allCardsValue_ = {}
CreateCardUtil.specialCardInfo_ = {}
CreateCardUtil.SPECIAL_CARD_ID_ALL_RANDOM = 1 -- 全随机
CreateCardUtil.SPECIAL_CARD_ID_RANDOM = 2 -- 玩家随机选择满足权值大于8的手牌
CreateCardUtil.SPECIAL_CARD_ID_CONTROL = 3 -- 强控，玩家随机选择大小王与2的个数
CreateCardUtil.SPECIAL_CARD_ID_ALL_BOMB = 4 -- 三家各有一个炸弹
CreateCardUtil.SPECIAL_CARD_ID_BOMB = 5 -- 玩家最少有一个炸弹
CreateCardUtil.SPECIAL_CARD_ID_THREE = 6 -- 玩家最少有一个三张的牌型
CreateCardUtil.SPECIAL_CARD_ID_SPLIT = 7 -- 补断，玩家的手牌中抽取三张放入底牌
CreateCardUtil.SPECIAL_CARD_ID_STRIGHT = 8 -- 玩家手牌满足6手以下

local specialCardName = {
    "全随机",
    "全随机+我改善",
    "我强控",
    "全多炸",
    "我多炸",
    "我多三",
    "我补断",
    "我顺",
}

local function _insertCard(self, original, seat)
    table.insert(self.singleGameManager_:getSomeOneCardsInt(seat), original)
    self:addCard(Card.new(original), seat)
    self:removeFromAllCard(original)
end

-- 根据牌值创建炸弹
local function _createBomb(self, original, seat)
    _insertCard(self, original, seat)
    local i = 1
    local j = 1
    local isToSmall = true
    while true do
        if isToSmall and original - 13 * i >= 0 then
            _insertCard(self, original - 13 * i, seat)
            i = i + 1
        else
            isToSmall = false
            if original + 13 * j <= 51 then
                _insertCard(self, original + 13 * j, seat)
                j = j + 1
            else
                break
            end
        end
    end
end

-- 根据牌值创建三张
local function _createThreeCard(self, original, seat)
    local handCardInt = self.singleGameManager_:getSomeOneCardsInt(seat)
    for k, cardInt in pairs(handCardInt) do
        if cardInt % 13 + 3 == original % 13 + 3 then
            return false
        end
    end
    _insertCard(self, original, seat)
    local i = 1
    local j = 1
    local isToSmall = true
    local cardCount = 1
    while true do
        if cardCount > 2 then
            break
        end
        
        if isToSmall and original - 13 * i >= 0 then
            _insertCard(self, original - 13 * i, seat)
            i = i + 1
            cardCount = cardCount + 1
        else
            isToSmall = false
            if original + 13 * j <= 51 then
                _insertCard(self, original + 13 * j, seat)
                j = j + 1
                cardCount = cardCount + 1
            else
                break
            end
        end
    end
    return true
end

-- 判断是否是王，如果是王则创建火箭
local function _checkIsJoker(self, original, seat, isInsert)
    local otherJoker = nil
    if original == 52 then
        otherJoker = 53
    elseif original == 53 then
        otherJoker = 52
    end
    if otherJoker then
        if isInsert then
            _insertCard(self, original, seat)
            _insertCard(self, otherJoker, seat)
        end
        return true
    else
        return false
    end
end

local _originalListToStr = function(originalList)
    local str = ""
    for k,v in pairs(originalList) do
        if v == 53 then
            str = str .. "大王"
        elseif v == 52 then
            str = str .. "小王"
        else
            str = str .. tostring(v % 13 + 3)
        end
    end
    return str
end

function CreateCardUtil:ctor()
	self.singleGameManager_ = require('single_game.SingleGameManager')
end

function CreateCardUtil:createCard(npcId, skillId)
    math.randomseed(tostring(os.time()):reverse():sub(1, 6))
    self.specialCardInfo_ = "开始创建手牌，NPC：%s，技能：%s，\n"
    local npcName = (npcId == -1 or npcId == nil) and "无" or lordSingleConfig.NPC_NAME[npcId]
    local skillName = (skillId == -1 or skillId == nil) and "无" or lordSingleConfig.NPC_SKILL_NAME[skillId]
    self.specialCardInfo_ = string.format(self.specialCardInfo_, npcName, skillName)
    if npcId == -1 or npcId == nil then
        self:createAllRandomCard()
    else
        if skillId == lordSingleConfig.NPC_SKILL_NO_BOMB then
            self:createMyBombCard()
        elseif skillId == lordSingleConfig.NPC_SKILL_NO_ROCKET then
            self:createMyBombCard(true, true)
        elseif skillId == lordSingleConfig.NPC_SKILL_NO_THREECARD then
            self:createMyThreeCard()
        elseif skillId == lordSingleConfig.NPC_SKILL_MUST_BOMB then
            self:createMyBombCard(true)
        elseif skillId == lordSingleConfig.NPC_SKILL_DISABLE_CARD then
            self:createHandCardWithOutJokerAnd2()
        elseif skillId == lordSingleConfig.NPC_SKILL_NO_SPLIT_JOKER then
            self:createHandCardWithDoubleJoker()
        else
            local specialCardId = -1
            -- 先获取NPC对应的特殊牌型几率
            local specialCardPercent = NPC_SPECIAL_CARD_PERCENT[npcId]
            -- 获取一个随机数，根据这个随机数来判断创建什么牌型
            local randomNum = math.random(1, 100)
            if specialCardPercent then
                for k, v in pairs(specialCardPercent) do
                    if v then
                        if randomNum >= v.min and randomNum <= v.max then
                            specialCardId = k
                            break
                        end
                    end
                end
            end
            self.specialCardInfo_ = self.specialCardInfo_.." NPC对应特殊牌型几率随机数为："..randomNum.."\n"
            if specialCardId ~= -1 then
                self:createSpecialCard(specialCardId)
            end
        end
    end
    return self.specialCardInfo_
end

function CreateCardUtil:createSpecialCard(specialCardId)
	math.randomseed(tostring(os.time()):reverse():sub(1, 6))
	if specialCardId == self.SPECIAL_CARD_ID_ALL_RANDOM then
		self:createAllRandomCard()
	elseif specialCardId == self.SPECIAL_CARD_ID_RANDOM then
		self:createRandomCard()
	elseif specialCardId == self.SPECIAL_CARD_ID_CONTROL then
        self:createControlCard()
	elseif specialCardId == self.SPECIAL_CARD_ID_ALL_BOMB then
        self:createAllBombCard()
	elseif specialCardId == self.SPECIAL_CARD_ID_BOMB then
        self:createMyBombCard()
	elseif specialCardId == self.SPECIAL_CARD_ID_THREE then
        self:createMyThreeCard()
	elseif specialCardId == self.SPECIAL_CARD_ID_SPLIT then
        self:createSplitCard()
	elseif specialCardId == self.SPECIAL_CARD_ID_STRIGHT then
        self:createStraightCard()
	end
end

function CreateCardUtil:createAllRandomCard()
    self.specialCardInfo_ = self.specialCardInfo_.." 牌型：全随机，"
	self:createHandCard(self.singleGameManager_.SELF)
    self:createHandCard(self.singleGameManager_.PRE)
    self:createHandCard(self.singleGameManager_.NEXT)
    self:createBottomCard()
end

-- 创建玩家随机固定权值牌型
function CreateCardUtil:createRandomCard()
    self.specialCardInfo_ = self.specialCardInfo_.." 牌型：全随机+我改善，"
	-- 先创建凑足8权值的牌型
	local cardPoint = 0
	local cardValues = {}
	-- 检查是否有重复的牌值，A和2最多4个
	local checkIsSame = function(cardValue, maxCount)
		local sameCount = 0
		for k,v in pairs(cardValues) do
			if v == cardValue then
				sameCount = sameCount + 1
				if maxCount == 0 then
					return false	
				else
					if sameCount > maxCount then
						return false
					end
				end
			end
		end
		return true
	end
	while cardPoint < MIN_CARD_POINT do
		local isFindValue = false
		local randomCardTypeIndex = math.random(1, #RANDOM_CARD_TYPE_POINT)
		local cardType = RANDOM_CARD_TYPE_POINT[randomCardTypeIndex]
		-- 如果随机到的是炸弹牌型，则需要再从炸弹牌值范围内随机一个具体的牌值
		if randomCardTypeIndex > 4 then
			local cardValue = math.random(cardType.cardMinValue, cardType.cardMaxValue)
			if checkIsSame(cardValue, cardType.maxCount) then
				-- 炸弹需要添加4张牌
				for i = 1, 4 do
					table.insert(cardValues, cardValue)	
				end
				isFindValue = true
			end
		else
			if checkIsSame(cardType.cardMinValue, cardType.maxCount) then
				table.insert(cardValues, cardType.cardMinValue)
				isFindValue = true
			end
		end
		if isFindValue then
			cardPoint = cardPoint + cardType.point
		end
	end
	-- 插入手牌
	local insertCard = function(cardValue)
		local original = nil
		if cardValue == cardValue_.CARD_POINT_LITTLE_JOKER then
			original = 52
		elseif cardValue == cardValue_.CARD_POINT_BIG_JOKER then
			original = 53
		else
			for k,v in pairs(self.allCards_) do
				if v % 13 + 3 == cardValue then
					original = v
					break
				end
			end
		end
		table.insert(self.singleGameManager_.selfCardsInt_, original)
		self:addCard(Card.new(original), self.singleGameManager_.SELF)
		self:removeFromAllCard(original)
	end
    self.specialCardInfo_ = self.specialCardInfo_.." 改善牌值："..table.concat(cardValues, ",")

	for k,v in pairs(cardValues) do
		insertCard(v)
	end

	-- 发剩余的牌
	self:createHandCard(self.singleGameManager_.SELF)
    self:createHandCard(self.singleGameManager_.PRE)
    self:createHandCard(self.singleGameManager_.NEXT)
    self:createBottomCard()
end

-- 创建强控牌型
function CreateCardUtil:createControlCard()
	-- 先随机出自己的强控牌型
    local allControl2CardsInt = {12, 25, 38, 51}
    local allControlJokerCardsInt = {52, 53}
    local randomNum = math.random(1, 100)
    local selfControlCardInfo = nil
    for k, v in pairs(CONTROL_CARD_TYPE_PERCENT) do
        if v and randomNum >= v.minPercent and randomNum <= v.maxPercent then
            selfControlCardInfo = v
            break
        end
    end
    local controlCardStr = "%s, %s, 2的个数为%d"
    controlCardStr = string.format(controlCardStr, (selfControlCardInfo.bigJokerCount == 1 and "有大王" or "无大王"), (selfControlCardInfo.littleJokerCount == 1 and "有小王" or "无小王"), selfControlCardInfo.card2Count)
    self.specialCardInfo_ = self.specialCardInfo_.. " 牌型：我强控，强控牌值："..controlCardStr

    -- 将大小王插入手牌
    if selfControlCardInfo.littleJokerCount == 1 then
        _insertCard(self, 52, self.singleGameManager_.SELF)
        table.remove(allControlJokerCardsInt, 1)
    end
    if selfControlCardInfo.bigJokerCount == 1 then
        _insertCard(self, 53, self.singleGameManager_.SELF)
        table.remove(allControlJokerCardsInt, #allControlJokerCardsInt)
    end

    -- 将2插入手牌
    for i = 1, selfControlCardInfo.card2Count do
        _insertCard(self, allControl2CardsInt[1], self.singleGameManager_.SELF)
        table.remove(allControl2CardsInt, 1)
    end

    -- 再将剩下的王和2随机发给NPC或者路人
    -- 先将剩余的王和2整合在一个数组
    local lastControlCards = {}
    for k,v in pairs(allControl2CardsInt) do
        table.insert(lastControlCards, v)
    end
    for k,v in pairs(allControlJokerCardsInt) do
        table.insert(lastControlCards, v)
    end
    -- 随机给NPC或者路人
    local i = 1
    while lastControlCards[i] do
        i = math.random(1, #lastControlCards)
        local randomSeat = math.random(self.singleGameManager_.NEXT, self.singleGameManager_.PRE)
        _insertCard(self, lastControlCards[i], randomSeat)
        table.remove(lastControlCards, i)
        i = 1
    end

    -- 发剩余的牌
    self:createHandCard(self.singleGameManager_.SELF)
    self:createHandCard(self.singleGameManager_.PRE)
    self:createHandCard(self.singleGameManager_.NEXT)
    self:createBottomCard()
end

-- 创建全炸弹牌型，三家每人一个炸弹
function CreateCardUtil:createAllBombCard()
    self.specialCardInfo_ = self.specialCardInfo_.. " 牌型：全炸弹，"
    local randomCardIndex = math.random(1, #self.allCards_)
    if not _checkIsJoker(self, self.allCards_[randomCardIndex], self.singleGameManager_.SELF, true) then
        _createBomb(self, self.allCards_[randomCardIndex], self.singleGameManager_.SELF)
    end
    local selfBombValue = _originalListToStr(self.singleGameManager_.selfCardsInt_)
    randomCardIndex = math.random(1, #self.allCards_)
    if not _checkIsJoker(self, self.allCards_[randomCardIndex], self.singleGameManager_.PRE, true) then
        _createBomb(self, self.allCards_[randomCardIndex], self.singleGameManager_.PRE)
    end
    local preBombValue = _originalListToStr(self.singleGameManager_.preCardsInt_)
    randomCardIndex = math.random(1, #self.allCards_)
    if not _checkIsJoker(self, self.allCards_[randomCardIndex], self.singleGameManager_.NEXT, true) then
        _createBomb(self, self.allCards_[randomCardIndex], self.singleGameManager_.NEXT)
    end
    local nextBombValue = _originalListToStr(self.singleGameManager_.nextCardsInt_)
    self.specialCardInfo_ = self.specialCardInfo_ .. string.format(" 玩家炸弹：%s，上家炸弹：%s，下家炸弹：%s", selfBombValue, preBombValue, nextBombValue)

    -- 发剩余的牌
    self:createHandCard(self.singleGameManager_.SELF)
    self:createHandCard(self.singleGameManager_.PRE)
    self:createHandCard(self.singleGameManager_.NEXT)
    self:createBottomCard()
end

--[[--
    创建我多炸牌型
    @params isIncludeJoker 是否包含双王，用来创建禁止火箭或者炸弹火箭必出等特殊牌型用，禁止火箭时默认炸弹个数为1，炸弹火箭必出时炸弹个数不限制
]] 
function CreateCardUtil:createMyBombCard(isIncludeJoker, isLimitBombCount)
    self.specialCardInfo_ = self.specialCardInfo_.. " 牌型：我多炸，"
    local randomNum = math.random(1, 100)
    local bombCount = 0
    -- 随机取到炸弹个数
    for k, v in pairs(BOMB_CARD_COUNT_PERCENT) do
        if randomNum >= v.minPercent and randomNum <= v.maxPercent then
            bombCount = v.count
            break
        end
    end

    if isIncludeJoker then
        _insertCard(self, 52, self.singleGameManager_.SELF)
        _insertCard(self, 53, self.singleGameManager_.SELF)
        if isLimitBombCount then
            bombCount = 0
        end
    end
    if log_util.isDebug() == true then
        log_util.i(TAG, "createMyBombCard IN bombCount is ", bombCount)
    end

    for i = 1, bombCount do
        randomNum = math.random(1, #self.allCards_)
        if not _checkIsJoker(self, self.allCards_[randomNum], self.singleGameManager_.SELF, true) then
            _createBomb(self, self.allCards_[randomNum], self.singleGameManager_.SELF)
        end
    end
    self.specialCardInfo_ = self.specialCardInfo_ .. "玩家炸弹：" .. _originalListToStr(self.singleGameManager_.selfCardsInt_)

    -- 发剩余的牌
    self:createHandCard(self.singleGameManager_.SELF)
    self:createHandCard(self.singleGameManager_.PRE)
    self:createHandCard(self.singleGameManager_.NEXT)
    self:createBottomCard()
end

function CreateCardUtil:createMyThreeCard()
    self.specialCardInfo_ = self.specialCardInfo_.. " 牌型：我多三，"
    local randomNum = math.random(1, 100)
    local threeCardCount = 0
    -- 随机取到三张个数
    for k, v in pairs(THREE_CARD_COUNT_PERCENT) do
        if randomNum >= v.minPercent and randomNum <= v.maxPercent then
            threeCardCount = v.count
            break
        end
    end
    if log_util.isDebug() == true then
        log_util.i(TAG, "createMyThreeCard IN threeCardCount is ", threeCardCount)
    end

    local i = 1
    while i <= threeCardCount do
        randomNum = math.random(1, #self.allCards_)
        local original = self.allCards_[randomNum]
        if not _checkIsJoker(self, original, self.singleGameManager_.SELF, false) then
            if _createThreeCard(self, original, self.singleGameManager_.SELF) then
                i = i + 1
            end
        end
    end
    self.specialCardInfo_ = self.specialCardInfo_ .. " 玩家三张：" .. _originalListToStr(self.singleGameManager_.selfCardsInt_)

    local selfCardsInt = self.singleGameManager_:cloneIntList(self.singleGameManager_.selfCardsInt_)
    -- 发剩余的牌
    self:createHandCard(self.singleGameManager_.SELF, selfCardsInt, false, false, false, true)
    self:createHandCard(self.singleGameManager_.PRE)
    self:createHandCard(self.singleGameManager_.NEXT)
    self:createBottomCard()
end

-- 创建顺子牌型
function CreateCardUtil:createStraightCard()
    self.specialCardInfo_ = self.specialCardInfo_.. " 牌型：我顺，"
    local cards = self.allCards_
    local minLength = straightLengthRange.min
    local maxLength = straightLengthRange.max
    local straightLength = math.random(minLength, maxLength)
    local straightCount = 1
    local handCardsInt = {}
    if straightLength < 7 then
        straightCount = 2
    end
    local index = math.random(1, #cards)
    local original = cards[index]
    local checkOriginalIsLessThan2 = function (cardOriginal)
        while cardOriginal > 51 or cardOriginal % 13 + 3 == cardValue_.CARD_POINT_2 do
            index = math.random(1, #cards)
            cardOriginal = cards[index]
        end
        return cardOriginal
    end

    local checkOriginalIsSame = function (value)
        local i = 1
        while handCardsInt[i] do
            if handCardsInt[i] == value then
                return true
            else
                i = i + 1
            end
        end

        return false
    end
    original = checkOriginalIsLessThan2(original)
    -- if log_util.isDebug() == true then
        -- log_util.i(TAG, "createStraightCard IN first card is ", original % 13 + 3, " original is ", original)
    -- end

    for i = 1, straightCount do
        -- if log_util.isDebug() == true then
            -- log_util.i(TAG, "createStraightCard IN straightCount is ", straightCount, " straightLength is ", straightLength)
        -- end

        local straightList = {}
        local toSmall = true
        local tempOriginal = original
        while #straightList < straightLength do
            -- if log_util.isDebug() == true then
                -- log_util.i(TAG, "createStraightCard IN original is ", original)
            -- end

            if not checkOriginalIsSame(original) then
                table.insert(straightList, original)
                self:removeFromAllCard(original)
            else
                if toSmall then
                    original = original + 1
                else
                    original = original - 1
                end
            end
            local originalMulti = math.random(0, 3)
            if original - 13 < 0 then
                while true do
                    -- if log_util.isDebug() == true then
                        -- log_util.i(TAG, "createStraightCard IN original is ", original - 13 * originalMulti, " originalMulti is ", originalMulti, " value is ", original % 13 + 3)
                    -- end

                    if original + 13 * originalMulti <= 50 then
                        original = original + 13 * originalMulti
                        break
                    else
                        originalMulti = math.random(0, 3)
                    end
                end
            else
                while true do
                    -- if log_util.isDebug() == true then
                        -- log_util.i(TAG, "createStraightCard IN original is ", original - 13 * originalMulti, " originalMulti is ", originalMulti, " value is ", original % 13 + 3)
                    -- end

                    if original - 13 * originalMulti >= 0 then
                        original = original - 13 * originalMulti
                        break
                    else
                        originalMulti = math.random(0, 3)
                    end
                end
            end
            if toSmall then
                original = original - 1
            else
                original = original + 1
            end
            -- if log_util.isDebug() == true then
                -- log_util.i(TAG, "createStraightCard IN original is ", original, " value is ", original % 13 + 3)
            -- end

            if original < 0 or original % 13 + 3 == cardValue_.CARD_POINT_2 then
                original = tempOriginal + 1
                toSmall = false
            end
        end
        local straightStr = ""
        table.sort(straightList, sortOriginal)
        for k,v in pairs(straightList) do
            table.insert(handCardsInt, v)
            straightStr = straightStr .. v % 13 + 3 .. " "
        end
        -- if log_util.isDebug() == true then
            -- log_util.i(TAG, "createStraightCard IN straightStr is ", straightStr)
        -- end

        if i < straightCount then
            index = math.random(1, #cards)
            original = cards[index]
            straightLength = math.random(minLength, maxLength)
            while straightLength + #handCardsInt > (TOTAL_CARD_COUNT - BOTTOM_CARD_COUNT) / PLAYER_COUNT do
                straightLength = math.random(minLength, maxLength)
            end
            original = checkOriginalIsLessThan2(original)
        end
    end

    for k,v in pairs(handCardsInt) do
        table.insert(self.singleGameManager_:getSomeOneCardsInt(self.singleGameManager_.SELF), v)
        self:addCard(Card.new(v), self.singleGameManager_.SELF)
    end
    self.specialCardInfo_ = self.specialCardInfo_ .. " 玩家顺子：" .. _originalListToStr(self.singleGameManager_.selfCardsInt_)

    self:createHandCard(self.singleGameManager_.SELF, handCardsInt, nil, nil, true)
    self:createHandCard(self.singleGameManager_.PRE)
    self:createHandCard(self.singleGameManager_.NEXT)
    self:createBottomCard()
end

--[[--
    创建补断牌型
]]
function CreateCardUtil:createSplitCard()
    self.specialCardInfo_ = self.specialCardInfo_.. " 牌型：我补断，"
    -- 先随机出需要补断的牌型
    local randomNum = math.random(1, 100)
    local splitCardTypeInfo = nil
    for k, v in pairs(SPLIT_CARD_TYPE_PERCENT) do
        if randomNum >= v.percentMin and randomNum <= v.percentMax then
            splitCardTypeInfo = v
            break
        end
    end

    -- 如果是大于6张的单顺，则需要再随机生成一个单顺的长度(6-12)
    local strightLength = 0
    if splitCardTypeInfo then
        if splitCardTypeInfo.strightMinLength ~= splitCardTypeInfo.strightMaxLength then
            strightLength = math.random(splitCardTypeInfo.strightMinLength, splitCardTypeInfo.strightMaxLength)
        else
            strightLength = splitCardTypeInfo.strightMinLength
        end
    end

    -- 是单顺还是双顺还是三顺
    local baseCardCount = splitCardTypeInfo.baseCardCount

    -- 随机生成顺牌的起始牌值/结尾牌值，如果随机出的起始牌值/结尾牌值不够生成足够长度的顺子则重新随机
    local startCardValue = math.random(cardValue_.CARD_POINT_3, cardValue_.CARD_POINT_A)
    while true do
        if startCardValue - strightLength + 1 >= cardValue_.CARD_POINT_3 or startCardValue + strightLength - 1 <= cardValue_.CARD_POINT_A then
            break
        else
            startCardValue = math.random(cardValue_.CARD_POINT_3, cardValue_.CARD_POINT_A)    
        end
    end

    -- 判断是由大至小取还是由小至大取
    local isToSmall = startCardValue - strightLength + 1 >= cardValue_.CARD_POINT_3

    local handCardInt = {}
    local handCardValue = {}
    -- 牌值数组第一位是3，所以下标需要用牌值-2
    local index = startCardValue - 2

    while true do
        for i = 1, baseCardCount do
            local randomIndex = math.random(1, #self.allCardsValue_[index])
            table.insert(handCardInt, self.allCardsValue_[index][randomIndex])
            table.remove(self.allCardsValue_[index], randomIndex)
        end
        if isToSmall then
            index = index - 1
        else
            index = index + 1
        end
        if #handCardInt >= baseCardCount * strightLength then
            break
        end
    end

    -- 从顺子牌型中随机抽出一张放入底牌
    local bottomCardIndex = math.random(1, #handCardInt)
    local bottomCardArray = {} -- 用来过滤在发剩余手牌时不发这张牌
    local bottomCardStr = "插入底牌牌值：" .. handCardInt[bottomCardIndex] % 13 + 3
    table.insert(bottomCardArray, handCardInt[bottomCardIndex])
    _insertCard(self, handCardInt[bottomCardIndex], self.singleGameManager_.arrayType_.BOTTOM)
    table.remove(handCardInt, bottomCardIndex)

    for k, v in pairs(handCardInt) do
        table.insert(handCardValue, v % 13 + 3)
        _insertCard(self, v, self.singleGameManager_.SELF)
    end
    if log_util.isDebug() == true then
        log_util.i(TAG, "createSplitCard IN handCardValue is ", table.concat(handCardValue, ", "))
    end

    self.specialCardInfo_ = self.specialCardInfo_ .. " 玩家补断牌型：" .. _originalListToStr(self.singleGameManager_.selfCardsInt_)
    self.specialCardInfo_ = self.specialCardInfo_ .. ", " .. bottomCardStr

    self:createHandCard(self.singleGameManager_.SELF, bottomCardArray)
    self:createHandCard(self.singleGameManager_.PRE)
    self:createHandCard(self.singleGameManager_.NEXT)
    self:createBottomCard()
end

--发手牌
function CreateCardUtil:createHandCard(pos, specialHandCardInt, isSingleCardSpecial, lessThen, isStraight, isCheckThreeCard)
    local cards = self.allCards_
    print(TAG .. ":createHandCard IN cards count is " .. #cards)

    local handCardCount = (TOTAL_CARD_COUNT - BOTTOM_CARD_COUNT) / PLAYER_COUNT
    if self.singleGameManager_.isUseTestCard_ then
        for i=1, #self.singleGameManager_:getTestCard(pos) do
            local original = self.singleGameManager_:getTestCard(pos)[i]
            if pos == self.singleGameManager_.SELF then
                table.insert(self.singleGameManager_.selfCardsInt_, original)
            elseif pos == self.singleGameManager_.PRE then
                table.insert(self.singleGameManager_.preCardsInt_, original)
            elseif pos == self.singleGameManager_.NEXT then
                table.insert(self.singleGameManager_.nextCardsInt_, original)
            end
			self:removeFromAllCard(original)
            self:addCard(Card.new(original), pos)
        end
    else
        local handCardInt = nil
        if pos == self.singleGameManager_.SELF then
            handCardInt = self.singleGameManager_.selfCardsInt_
        elseif pos == self.singleGameManager_.PRE then
            handCardInt = self.singleGameManager_.preCardsInt_
        elseif pos == self.singleGameManager_.NEXT then
            handCardInt = self.singleGameManager_.nextCardsInt_
        end
        if #handCardInt > 0 then
            handCardCount = handCardCount - #handCardInt
        end

        local showHandCard = function (cardInt)
            if cardInt then
                local specialHandCardStr = ""
                for k,v in pairs(cardInt) do
                    specialHandCardStr = specialHandCardStr .. v % 13 + 3 .. " "
                end
                -- if log_util.isDebug() == true then
                    -- log_util.i(TAG, "createHandCard IN specialHandCardStr is ", specialHandCardStr)
                -- end
            end
        end

        local checkIsCreateNewThreeCards = function(handCards, newOriginal)
            local cardCount = 0
            for k,v in pairs(handCards) do
                if v % 13 + 3 == newOriginal % 13 + 3 then
                    cardCount = cardCount + 1
                end
            end
            if log_util.isDebug() == true then
                log_util.i(TAG, "checkIsCreateNewThreeCards IN cardCount is ", cardCount)
            end

            if cardCount >= 2 then
                return true
            else
                return false
            end
        end

        showHandCard(specialHandCardInt)

        for i=1, handCardCount do
            local index = math.random(1, #cards)
            if specialHandCardInt then
                local j = 1
                while specialHandCardInt[j] do
                    local randomCardValue = isStraight and cards[index] or cards[index] % 13 + 3
                    local handCardValue = isStraight and specialHandCardInt[j] or specialHandCardInt[j] % 13 + 3
                    -- if log_util.isDebug() == true then
                        -- log_util.i(TAG, "createHandCard IN randomCardValue is ", randomCardValue, " handCardValue is ", handCardValue)
                    -- end

                    if randomCardValue == handCardValue then
                        index = math.random(1, #cards)
                        j = 1
                    else
                        if isSingleCardSpecial then
                            if randomCardValue == cardValue_.CARD_POINT_7 or randomCardValue == cardValue_.CARD_POINT_10 then
                                index = math.random(1, #cards)
                                j = 1
                            else
                                j = j + 1    
                            end
                        else
                            j = j + 1
                        end
                    end
                end
            end

            if lessThen then
                while cards[index] % 13 + 3 > lessThen or cards[index] > 51 do
                    index = math.random(1, #cards)
                end
            end

            if isCheckThreeCard then
                while checkIsCreateNewThreeCards(handCardInt, cards[index]) do
                    index = math.random(1, #cards)
                end
            end

            table.insert(handCardInt, cards[index])
            showHandCard(handCardInt)
            self:addCard(Card.new(cards[index]), pos)
            self:removeFromAllCard(cards[index])
        end
        if log_util.isDebug() == true then
            log_util.i(TAG, "self.allCards_ count is ", #self.allCards_)
        end

    end
end

function CreateCardUtil:createHandCardWithOutJokerAnd2()
    self:removeFromAllCard(51)
    self:removeFromAllCard(52)
    self:removeFromAllCard(53)

    TOTAL_CARD_COUNT = TOTAL_CARD_COUNT - 3
    self:createHandCard(self.singleGameManager_.SELF)
    self:createHandCard(self.singleGameManager_.PRE)
    self:createHandCard(self.singleGameManager_.NEXT)
    self:createBottomCard()
end

function CreateCardUtil:createHandCardWithOne2Only()
    local handCardsInt = {}
    table.insert(handCardsInt, 51)
    self:removeFromAllCard(51)
    for k,v in pairs(handCardsInt) do
        table.insert(self.singleGameManager_.selfCardsInt_, v)
        self:addCard(Card.new(v), self.singleGameManager_.SELF)
    end

    self:createHandCard(self.singleGameManager_.SELF, handCardsInt, nil, cardValue_.CARD_POINT_A)
end

function CreateCardUtil:createHandCardWithDoubleJokerAnd2()
    local handCardsInt = {}
    table.insert(handCardsInt, 51)
    table.insert(handCardsInt, 38)
    table.insert(handCardsInt, 52)
    table.insert(handCardsInt, 53)
    self:removeFromAllCard(51)
    self:removeFromAllCard(52)
    self:removeFromAllCard(53)
    self:removeFromAllCard(38)
    for k,v in pairs(handCardsInt) do
        table.insert(self.singleGameManager_.preCardsInt_, v)
        self:addCard(Card.new(v), self.singleGameManager_.PRE)
    end

    self:createHandCard(self.singleGameManager_.PRE)
end

function CreateCardUtil:createHandCardWithDoubleJoker()
    local handCardsInt = {}
    table.insert(handCardsInt, 52)
    table.insert(handCardsInt, 53)
    self:removeFromAllCard(52)
    self:removeFromAllCard(53)
    for k,v in pairs(handCardsInt) do
        table.insert(self.singleGameManager_.selfCardsInt_, v)
        self:addCard(Card.new(v), self.singleGameManager_.SELF)
    end

    self:createHandCard(self.singleGameManager_.SELF)
    self:createHandCard(self.singleGameManager_.PRE)
    self:createHandCard(self.singleGameManager_.NEXT)
    self:createBottomCard()
end

function CreateCardUtil:createSingleCard(npcSeat)
    local cards = self.allCards_
    local handCards = {}
    local handCardsInt = {}
    
    local singleCardCount = math.random(singleCardsCountRange.min, singleCardsCountRange.max)
    local valueList = {}
    local dropCards = {7, 10}
    local dropCard = dropCards[math.random(1, #dropCards)]

    local checkIsSame = function ()
        local flag = false
        table.sort(valueList, sortInt)
        
        local i = 1
        if valueList[i] == dropCard then
            flag = true
        else
            local j = i + 1
            local sameCount = 0
            while valueList[j] do
                if valueList[j] == valueList[i] then
                    flag = true
                    break
                end

                i = i + 1
                j = j + 1
            end
        end
        
        return flag
    end

    for i = 1, singleCardCount do
        local index = math.random(1, #cards)
        
        while true do
            valueList = {}
            for key, var in pairs(handCardsInt) do
                table.insert(valueList, var % 13 + 3)
            end
            local newCardValue = cards[index] % 13 + 3
            
            table.insert(valueList, newCardValue)
            -- if log_util.isDebug() == true then
                -- log_util.i(TAG, "valueList is ", vardump(valueList))
            -- end

            if checkIsSame(valueList) then
                index = math.random(1, #cards)
            else
                break
            end
        end
        table.insert(handCardsInt, cards[index])
        table.remove(cards, index)
    end

    for k,v in pairs(handCardsInt) do
        table.insert(self.singleGameManager_:getSomeOneCardsInt(npcSeat), v)
        self:addCard(Card.new(v), npcSeat)
    end

    self:createHandCard(npcSeat, handCardsInt, true)
end

function CreateCardUtil:createBombCard(npcSeat)
    local cards = self.allCards_
    local handCards = {}
    local handCardsInt = {}
    local bombCardCount = math.random(bombCardsCountRange.min, bombCardsCountRange.max)
    -- local bombCardCount = 2
    
    -- 校验是否4张牌都未使用
    local checkCanMakeBombByOriginal = function(original)
        -- 取到original最小的一张牌
        local smallLestSameCardInt = -1
        local i = 0
        while original - 13 * i >= 0 do
            smallLestSameCardInt = original - 13 * i
            i = i + 1
        end

        i = 0
        while smallLestSameCardInt + 13 * i < 52 do
            local isUsed = true
            for k,v in pairs(cards) do
                if smallLestSameCardInt + 13 * i == v then
                    isUsed = false
                    break
                end
            end
            if isUsed then
                return false
            else
                i = i + 1
            end
        end

        return true
    end

    for i = 1, bombCardCount do
        local index = math.random(1, #cards)
        while not checkCanMakeBombByOriginal(cards[index]) do
            index = math.random(1, #cards)
        end
        table.insert(handCardsInt, cards[index])
        table.insert(self.singleGameManager_.bombValues_, cards[index] % 13 + 3)
        table.remove(cards, index)
    end

    for k,v in pairs(handCardsInt) do
        local smallLestSameCardInt = -1
        local i = 0
        while v - 13 * i >= 0 do
            smallLestSameCardInt = v - 13 * i
            i = i + 1
        end
        i = 0
        while smallLestSameCardInt + 13 * i < 52 do
            table.insert(self.singleGameManager_:getSomeOneCardsInt(npcSeat), smallLestSameCardInt + 13 * i)
            self:removeFromAllCard(smallLestSameCardInt + 13 * i)
            self:addCard(Card.new(smallLestSameCardInt + 13 * i), npcSeat)
            i = i + 1
        end
    end

    self:createHandCard(npcSeat)
end

function CreateCardUtil:createDoubleCard(npcSeat)
    local cards = self.allCards_
    local handCards = {}
    local handCardsInt = {}
    
    local doubleCardsCount = math.random(doubleCardsCountRange.min, doubleCardsCountRange.max)
    local valueList = {}
    
    local checkIsSame = function ()
        local flag = false
        table.sort(valueList, sortInt)
        
        local i = 1
        local j = i + 1
        local sameCount = 0
        while valueList[j] do
            if valueList[j] == valueList[i] then
                flag = true
                break
            end

            if valueList[j] > 51 or valueList[i] > 51 then
                flag = true
                break
            end

            if valueList[j] - valueList[i] == 1 or valueList[j] - valueList[i] == -1 then
                sameCount = sameCount + 1
            end
            if sameCount >= 1 then
                flag = true
                break
            else
                i = i + 1
                j = j + 1
            end
        end
        return flag
    end
    
    for i = 1, doubleCardsCount do
        local index = math.random(1, #cards)
        local sameCount = 0
        while true do
            valueList = {}
            for key, var in pairs(handCardsInt) do
                table.insert(valueList, var % 13 + 3)
            end
            local newCardValue = cards[index] % 13 + 3
            
            table.insert(valueList, newCardValue)
            
            if checkIsSame(valueList) then
                index = math.random(1, #cards)
            else
                break
            end
        end
        table.insert(handCardsInt, cards[index])
        table.remove(cards, index)
    end

    for k,v in pairs(handCardsInt) do
        table.insert(self.singleGameManager_:getSomeOneCardsInt(npcSeat), v)
        if v + 13 > 51 then
            table.insert(self.singleGameManager_:getSomeOneCardsInt(npcSeat), v - 13)
            self:removeFromAllCard(v - 13)
            self:addCard(Card.new(v - 13), npcSeat)
        else
            table.insert(self.singleGameManager_:getSomeOneCardsInt(npcSeat), v + 13)
            self:removeFromAllCard(v + 13)
            self:addCard(Card.new(v + 13), npcSeat)
        end
        self:addCard(Card.new(v), npcSeat)
    end

    self:createHandCard(npcSeat, handCardsInt)
end

--发底牌
function CreateCardUtil:createBottomCard()
    local cards = self.allCards_
    if self.singleGameManager_.isUseTestCard_ then
        for i=1, #self.singleGameManager_:getTestCard(self.singleGameManager_.arrayType_.BOTTOM) do
            local original = self.singleGameManager_:getTestCard(self.singleGameManager_.arrayType_.BOTTOM)[i]
            self:removeFromAllCard(original)
            table.insert(self.singleGameManager_.bottomCardsInt_, original)
            self:addCard(Card.new(original), self.singleGameManager_.arrayType_.BOTTOM)
        end
    else
        for i=1, BOTTOM_CARD_COUNT - #self.singleGameManager_.bottomCardsInt_ do
            local index = math.random(1, #cards)
            table.insert(self.singleGameManager_.bottomCardsInt_, cards[index])
            self:addCard(Card.new(cards[index]), self.singleGameManager_.arrayType_.BOTTOM)
            self:removeFromAllCard(cards[index])
        end
    end
end

function CreateCardUtil:initAllCards()
	self.allCards_ = {}
    self.allCardsValue_ = {}
	TOTAL_CARD_COUNT = 54
    for key, var in pairs(allCards_) do
        self.allCards_[key] = var
    end

    for k,v in pairs(allCardsValue_) do
        self.allCardsValue_[k] = {}
        for key,value in pairs(v) do
            self.allCardsValue_[k][key] = value
        end
    end
end

--添加手牌
function CreateCardUtil:addCard(card, whom)
    local cardList = self.singleGameManager_:getSomeOneCards(whom)
    if cardList and card then
        table.insert(cardList, card)
    end
end

function CreateCardUtil:removeFromAllCard(original)
    for k,v in pairs(self.allCards_) do
        if v == original then
            table.remove(self.allCards_, k)
            break
        end
    end
end

function CreateCardUtil:translateCardObjToInt(selfCards, preCards, nextCards)
    self:initAllCards()
    
    local selfCardsInt = {}
    local preCardsInt = {}
    local nextCardsInt = {}
    local getCard = function(cardsObj, cardsInt)
        local i = 1
        while #cardsObj > 0 do
            local isFindCard = false
            for key, var in pairs(cardsObj) do
                if self.allCards_[i] == 52 then
                    if var == cardValue_.CARD_POINT_LITTLE_JOKER then
                        isFindCard = true
                    end
                elseif self.allCards_[i] == 53 then
                    if var == cardValue_.CARD_POINT_BIG_JOKER then
                        isFindCard = true
                    end
                elseif self.allCards_[i] % 13 + 3 == var then
                    isFindCard = true
                end
                if isFindCard then
                    table.insert(cardsInt, self.allCards_[i])
                    table.remove(cardsObj, key)
                    self:removeFromAllCard(self.allCards_[i])
                    i = 1
                    break
                end
            end
            if not isFindCard then
                i = i + 1
            end
        end
    end
    getCard(selfCards, selfCardsInt)
    getCard(preCards, preCardsInt)
    getCard(nextCards, nextCardsInt)

    return selfCardsInt, preCardsInt, nextCardsInt
end

function CreateCardUtil:randomCard(cards)
    local newCards = {}
    while #cards > 0 do
        local index = math.random(1, #cards)
        table.insert(newCards, cards[index])
        table.remove(cards, index)
    end
    return newCards
end

return CreateCardUtil
package.cpath = "../skynet/luaclib/?.so"
package.path = "./?.lua"

require "utils/table_util"
local file_util = require "utils/file_util"
local log_util = require "utils/log_util"
local CardPattern = require "logic/CardPattern"
local LordDef = require "data/LordDef"
local SingleGameConfig = require "single_game/SingleGameConfig"
local CardsInfo = require "logic/CardsInfo"
local test_path = file_util.get_preload_paths_in_root_path('./')

--package.path = package.path .. test_path

local SingleGameManager = require "single_game.SingleGameManager"

local TAG = 'game_starter'

local self = {}
self.single_game_mgr = SingleGameManager:new()
function init_game()
	self.single_game_mgr:reset()
	self.takeOutCardRecord_ = {}
	self.specialCardInfo_ = self.single_game_mgr:initCard(self.takeOutCardRecord_, -1, -1, 1, false, nil)

	table.printT(self.takeOutCardRecord_)
	print(self.specialCardInfo_)
end

function start_game()
	
end

--[[--
    构造单机游戏的lordData数据
]]
function createSingleLordData()
    if log_util.isDebug() == true then
        log_util.i(TAG, "createSingleLordData IN")
    end

    self.isAutoTakeOutLastCard_ = false

    if self.lord_data then
        self.lord_data:resetGame()
    else
        self.lord_data = require("data.LordData").new()
    end

    self.lord_data.state_ = LordUnionGameState.STATE_CALL_LORD
    self.lord_data.currentOperaterSeat_ = self.single_game_mgr:getFirstCallScoreSeat()
    self.lord_data.selfSeat_ = self.single_game_mgr.SELF
    self.lord_data:setInitCards(self.single_game_mgr:getSelfCardInt())
    self.lord_data:setBottomCards(self.single_game_mgr:getBottomCardInt())

    for i = 0, 2 do
        local lordPlayerInfoCls = require("data.LordPlayerInfo").new()
        if i == self.single_game_mgr.PRE then
            lordPlayerInfoCls.nickName_ = "路人甲"
        elseif i == self.single_game_mgr.NEXT then
            lordPlayerInfoCls.nickName_ = "路人乙"
        end

        lordPlayerInfoCls.score_ = 0
        lordPlayerInfoCls.cardCount_ = #self.single_game_mgr:getCardsBySeat(i)
        self.lord_data:setPlayerInfo(i, lordPlayerInfoCls)
    end

    return self.lord_data
end


function getGameData()
	if not self.lord_data then
		createSingleLordData()
	end
    return self.lord_data
end

function onFunction(type, param1, param2, param3)
    local lordData = getGameData()

    if log_util.isDebug() == true then
        log_util.i(TAG, "onFunction IN type is ", type)
    end

    if type == self.TYPE_CALL_SCORE then
        doCallScore(param1, param2)
    elseif type == self.TYPE_CLICK_PRODUCT_PASS then
        local lordData = getGameData()
        if lordData then
            if log_util.isDebug() == true then
                log_util.i(TAG, "canPass is ", lordData:canPass())
            end

            if lordData:canPass() then --非首出
                doTakeOutCard(nil, lordData.selfSeat_)
                --[[
                if self.currentView_ then
                    self.currentView_.ownPoker_:reset()
                    self.currentView_:setOwnPokerResponeTouch(true)
                end
                ]]
                return false
            end
        end
    elseif type == self.TYPE_CLICK_PRODUCT_CARDS then
        return doProduct(param2)
    elseif type == self.TYPE_CLICK_DIPLOMA_LOBBY then
        exitMatch(true)
    elseif type == self.TYPE_OWNPOKER_ANIM_FINISH then
        cardDispatchFinishListener()
    else
        print("unhandled type:", type)
    end
end

--[[--
    start call score
]]
function startCallScore()
    if log_util.isDebug() == true then
        log_util.i(TAG, "startCallScore IN ")
    end

    local lordData = getGameData()
    if lordData then
        lordData.canDisplayCallScore_ = true
        lordData.state_ = LordUnionGameState.STATE_CALL_LORD        
        lordData.currentOperaterSeat_ = self.single_game_mgr:getFirstCallScoreSeat()
        lordData.selfSeat_ = self.single_game_mgr.SELF
        if lordData.currentOperaterSeat_ ~= self.single_game_mgr.SELF then
            local callScore = self.single_game_mgr:getCallScore(lordData.currentOperaterSeat_)
            if log_util.isDebug() == true then
                log_util.i(TAG, "first call score is ", callScore, " seat is ", lordData.currentOperaterSeat_)
            end

            if callScore > lordData.validScore then
                lordData.validScore = callScore
            end
            onFunction(self.TYPE_CALL_SCORE, lordData.currentOperaterSeat_, callScore)
        else
            if log_util.isDebug() == true then
                log_util.i(TAG, "please call score!")

            end
        end
    end
end

function doCallScore(callSeat, score)
    local lordData = getGameData()
    if lordData then
        self.single_game_mgr:setCurrentCallSeat(callSeat)

        if lordData.callScoreCount_ == 1 then
            lordData.validScore = 0
            lordData.firstCallSeat = callSeat
        end
        if score <= lordData.validScore then
            score = 0
        else
            lordData.validScore = score
        end
        print("call score:" .. score .. ", callSeat:" .. callSeat)
        
        if score > 0 then
            lordData.bottomScore = score
            lordData.lordSeat = callSeat
        end
        lordData.state_ = LordUnionGameState.STATE_CALL_LORD
        if score == 3 or lordData.callScoreCount_ == 3 then
            if lordData.validScore == 0 then
                self.skillId_ = nil
                self.isReMatchForCallScore_ = true
                lordData.needPlayDealCards = true
                initSingleMatchData()
                --self:recover()
                return
            end
            lordData.state_ = LordUnionGameState.STATE_PLAY
            lordData.currentOperaterSeat_ = lordData.lordSeat
            initBottomCards()
        else
            callSeat = callSeat + 1
            if callSeat > 2 then
                callSeat = self.single_game_mgr.SELF
            end
            lordData.currentOperaterSeat_ = callSeat
            lordData.callScoreCount_ = lordData.callScoreCount_ + 1
            if callSeat == self.single_game_mgr.SELF then
                print('self call score')
                local nextCallScore = self.single_game_mgr:getCallScore(callSeat)
                onFunction(self.TYPE_CALL_SCORE, callSeat, nextCallScore)
            else
                local nextCallScore = self.single_game_mgr:getCallScore(callSeat)
                onFunction(self.TYPE_CALL_SCORE, callSeat, nextCallScore)
            end
        end
    end
end

--[[--
    初始化底牌
]]
--yanlz：嘻哈单机5期：经验奖励倍数优化：获胜时有加倍，获胜经验也加相同倍数：底牌加倍优化
function initBottomCards()
    log_util.i(TAG, "initBottomCards IN")

    local lordData = getGameData()
    if lordData then
        if true then
            self.single_game_mgr:addBottomCard(lordData.lordSeat)
            self.single_game_mgr:getBombValues()
            
            --self.currentView_:playDeclearLordAnim(lordData.lordSeat)
            --self.currentView_:cleanSpeak()
            --[[ --yanlz：IOS嘻哈1期：BUG#14091-[游戏中]AI底牌翻倍优化
            self.isShowBottomCardMulti_ = (lordData.lordSeat == SingleGameManager.SELF and self.npcInfo_ and 
                (self.npcInfo_.id == lordSingleConfig.NPC_ID_UNCLE or self.npcInfo_.id == lordSingleConfig.NPC_ID_AUNT))
                ]]
            self.isShowBottomCardMulti_ = ( self.npcInfo_ and (self.npcInfo_.id == lordSingleConfig.NPC_ID_UNCLE or self.npcInfo_.id == lordSingleConfig.NPC_ID_AUNT))
            --self.currentView_:setBottomCards(lordData:getBottomCards(), self.isShowBottomCardMulti_)

            local _, bottomMulti = LordUtil:getFundCardsMultiple(self.single_game_mgr:getBottomCardInt())
            lordData.bottomScore = self.isShowBottomCardMulti_ and lordData.bottomScore * bottomMulti or lordData.bottomScore
            --self.currentView_:setMultiple(lordData.bottomScore)
            --
            --yanlz：嘻哈单机5期：经验奖励倍数优化：获胜时有加倍，获胜经验也加相同倍数：底牌加倍优化
            --lordData.bottomCardMulti_ = self.isShowBottomCardMulti_ and bottomMulti or 1    --yanlz：底牌加倍--嘻哈茶馆只有双王/单王/对2的底牌加倍

            -- 这里设置状态时为了防止抢地主技能或者让地主技能时没有通过叫分来设置状态的情况
            lordData.state_ = LordUnionGameState.STATE_PLAY 

            lordData:setInitCards(lordData.arrCards)

            --如果自己是地主，则第一个出牌  
            if lordData.lordSeat == lordData.selfSeat_ and false then
            	--[[
                self.currentView_:addBottomCards(lordData:getBottomCards())
                if self.skillId_ == lordSingleConfig.NPC_SKILL_TIME_LIMIT then
                    self.currentView_:playSkillWandAndFireAnim()
                    self.currentView_:playSkillWandFlashAnim(-self.dimens_:getDimens(10), self.dimens_:getDimens(120), 0.6, 0.5, -10)
                else
                    self.currentView_:displayCountDown(lordData.currentOperaterSeat_)
                end
                ]]
            else
                --更新玩家的牌数量
                --self.currentView_:updatePlayerCardsNum(lordData.lordSeat, #SingleGameManager:getCardsBySeat(lordData.lordSeat))
                --self.currentView_:setOwnPokerResponeTouch(true)
                local params = {}
                params.lordSeat = lordData.lordSeat
                params.seat = lordData.lordSeat
                params.lastTakeOutSeat = -1
                if self.npcInfo_ then
                    params.npcId = self.npcInfo_.id
                else
                    params.npcId = -1
                end
                params.isMess = isMess()
                local takeOutCardGroup = self.single_game_mgr:doTakeOutCard(params)
                if takeOutCardGroup and takeOutCardGroup.cardList then
                    lordData:setCurHandFromCardObj(takeOutCardGroup.cardList)
                end
                doTakeOutCard(takeOutCardGroup, lordData.lordSeat)
            end
        end
    end
end

function isMess()
    return true
end

--[[--
    初始化单机比赛数据
]]
function initSingleMatchData()
    if log_util.isDebug() == true then
        log_util.i(TAG, "initSingleMatchData IN")
    end

    local startGameParam = require("game.data.model.StartGameParam").new()
    startGameParam.gameId_ = gameId
    self.startGameParam_ = startGameParam
    --[[
    local matchId, singleMatchData = self.single_game_mgr:getCurrentMatch()
    self.matchId_ = matchId
    log_util.i(TAG, "initSingleMatchData IN matchId is ", matchId)
    startGameParam.matchId_ = matchId
    startGameParam.singleMatchData_ = singleMatchData
    --]]
    createSingleLordData()
end

--[[--
    玩家出牌的逻辑处理
    @param cardObjList 需要出的牌型列表
]]
function doProduct(cardObjList, isNotCheckCardLimit)
    local lordData = getGameData()
    if lordData then
        local seat = self.single_game_mgr.SELF
        LordUtil:sortCards(cardObjList)
        if log_util.isDebug() == true then
            log_util.i(TAG, "doProduct IN lastTakeOutSeat is ", self.single_game_mgr.lastTakeOutSeat, " seat is ", seat)
        end

        if self.single_game_mgr.lastTakeOutSeat == seat then
            self.single_game_mgr.lastTakeOutCardGroup = nil
        end
        if log_util.isDebug() == true then
            log_util.i(TAG, "doProduct IN lastTakeOutCardGroup is ", self.single_game_mgr.lastTakeOutCardGroup)
        end

        local cardsInfo = CardPattern:parseCards(cardObjList)
        if cardsInfo then
            if log_util.isDebug() == true then
                log_util.i(TAG, "doProduct IN card type is ", cardsInfo.type, " value is ", cardsInfo.value)
            end

            local canTakeOut = canTakeOut(self.single_game_mgr.lastTakeOutCardGroup, cardsInfo, lordData)
            if log_util.isDebug() == true then
                log_util.i(TAG, "doProduct IN canTakeOut is ", canTakeOut)
            end

            if canTakeOut then
                if not checkCardTypeLimit then
                    checkLimitResult = checkCardTypeLimit(cardsInfo, cardObjList)
                    if not checkLimitResult then
                        return false
                    end
                end

                local takeOutCardGroup = {}
                takeOutCardGroup.cardList = cardObjList
                takeOutCardGroup.cardValue = cardsInfo.value
                takeOutCardGroup.cardType = cardsInfo.type

                local handCards = self.single_game_mgr:getCardsBySeat(seat)
                self.single_game_mgr:removeTakeoutCard(cardObjList, seat)
                local cardIntList = {}
                for k,v in pairs(cardObjList) do
                    table.insert(cardIntList, v.original)
                end
                lordData:removeCards(cardIntList)

                doTakeOutCard(takeOutCardGroup, lordData.selfSeat_)
                return true
            else
            	log_util.i("选择的牌不合理")                
            end
        end
    end
    return false
end

--[[--
    出牌逻辑处理
    @param takeOutCardGroup 当前出的牌的数据
    @param seat 当前出牌的座位号
]]
--yanlz: 嘻哈单机5期：炸弹规则需要改为JJ炸弹规则
function doTakeOutCard(takeOutCardGroup, seat, isAutoTakeOutAICards)
    local lordData = getGameData()
    if lordData then
        --测试代码
        local testIsOver = self.single_game_mgr:getIsGameOver()
        local takeOutCards = {}
        local takeOutCardType = -1
        local cardRecord = self.single_game_mgr:getCardRecord()
        local isOver = false
        local nextSeat = seat + 1
        if nextSeat > 2 then
            nextSeat = 0
        end
        local handCards = self.single_game_mgr:getCardsBySeat(seat)
        local playerInfo = lordData:getPlayerInfo(seat)
        local takeOutCardRecord = {}
        takeOutCardRecord.seat = seat
        if takeOutCardGroup then
            takeOutCards = takeOutCardGroup.cardList
            takeOutCardType = takeOutCardGroup.cardType

            self.lastTakeOutCardGroup_ = {}
            local cardIntList = {}
            for k,v in pairs(takeOutCards) do
                table.insert(cardIntList, v.original)
            end
            self.lastTakeOutCardGroup_.cardList = cardIntList
            self.lastTakeOutCardGroup_.cardValue = takeOutCardGroup.cardValue
            self.lastTakeOutCardGroup_.cardType = takeOutCardGroup.cardType

            self.lastTakeOutCardGroupSeat_ = seat

            takeOutCardRecord.cardList = takeOutCards
            takeOutCardRecord.cardValue = takeOutCardGroup.cardValue
            takeOutCardRecord.cardType = takeOutCardGroup.cardType
        else
            takeOutCardRecord.cardList = {}
            takeOutCardRecord.cardValue = -1
            takeOutCardRecord.cardType = -1
        end

        --[[--yanlz：嘻哈单机5期：自测bug：打牌过程中偶现丢失声音和动画：尝试将牌型解析与动画播放近一点
        --计算牌型
        local cardInfo = CardPattern:parseCards(takeOutCards)
        ]]

        local pos = lordData:getPosBySeat(seat)
        local posNext = nil

        table.insert(cardRecord, takeOutCardRecord)

        LordUtil:sortCards(takeOutCards)

        -- 计算地主出的手数，用来判断是否是春天
        if seat == lordData.lordSeat and takeOutCards and #takeOutCards > 0 then
            lordData.lordTakeOutCardCount_ = lordData.lordTakeOutCardCount_ + 1
        end

        lordData:setLastTakeOutFromCardObj(seat, takeOutCards)
        lordData:setCurHandFromCardObj(seat, takeOutCards)
        lordData:setLastHandFromCardObj(nextSeat, lordData:getCurHand(nextSeat))

        if takeOutCardType == CardPattern.FOUR_CARDS or takeOutCardType == CardPattern.DOUBLE_JOKER then
            --yanlz: 嘻哈单机5期：炸弹规则需要改为JJ炸弹规则--
            if lordData.jjBomb then
                lordData.multiple = lordData.multiple + 1
            else
                lordData.multiple = lordData.multiple * 2
            end
            lordData.bombNum = lordData.bombNum + 1
            --self.currentView_:setMultiple(lordData.multiple * lordData.bottomScore)
        end

        --获取所出牌的信息
        playerInfo.isTakeOuted_ = true
        if handCards then
            isOver = #handCards == 0
            if #handCards >= 0 then
                --更新玩家牌数量
                --self.currentView_:updatePlayerCardsNum(seat, #handCards)
                playerInfo.cardCount_ = #handCards
            end
        end

        if pos == LordDef.PLAYER_POSITION_PRE then
            posNext = LordDef.PLAYER_POSITION_SELF
        elseif pos == LordDef.PLAYER_POSITION_SELF then
            --self.currentView_:setLastTakeOutCard(nil) --清除上一手牌信息
            posNext = LordDef.PLAYER_POSITION_NEXT
        elseif pos == LordDef.PLAYER_POSITION_NEXT then
            posNext = LordDef.PLAYER_POSITION_PRE
        end

        --计算牌型
        local cardInfo = CardPattern:parseCards(takeOutCards)    --yanlz：嘻哈单机5期：自测bug：打牌过程中偶现丢失声音和动画：尝试将牌型解析与动画播放近一点
        --[[
        if seat == lordData.selfSeat_ then
            self.currentView_:cleanTakoutCards(pos)
            self.currentView_:doSelfProduct(takeOutCards)
        else
            self.currentView_:displayTakeoutCards(seat, takeOutCards)
            self.currentView_:displayTakeoutCardsAnim(cardInfo, seat)
            self.currentView_:playSound(cardInfo)
        end
        self.currentView_:cleanTakoutCards(posNext)
		]]
        if IS_RECORD then
            local cardStr = ""
            local cardIntStr = ""
            for key, var in pairs(takeOutCards) do
                cardStr = cardStr..var.value..", "
                cardIntStr = cardIntStr..var.original..", "
            end

            if self.takeOutCardRecord_ == nil then
                self.takeOutCardRecord_ = {}
            end
            table.insert(self.takeOutCardRecord_, string.format("doTakeOutCard IN takeOutCards %s original is %s takeOut seat is %d", cardStr, cardIntStr, seat))
            LuaDataFile.save(self.takeOutCardRecord_ or {}, SINGLELORD_RECORD_FILE_PATH)
            if log_util.isDebug() == true then
                log_util.i(TAG, "doTakeOutCard IN takeOutCards ", cardStr, " takeOut seat is ", seat)
            end
        end

        lordData.currentOperaterSeat_ = nextSeat
        if pos == LordDef.PLAYER_POSITION_SELF then
            if takeOutCardGroup then
                self.single_game_mgr.lastTakeOutCardGroup = takeOutCardGroup
                self.single_game_mgr.lastTakeOutSeat = seat
            end
        end

        local isNPCSplitJoker = checkNPCIsSplitJoker(cardInfo, seat)
        if isNPCSplitJoker then
            doNPCSplitJoker(seat)
            return
        end

        if log_util.isDebug() == true then
            log_util.i(TAG, "isOver is ", isOver, " testIsOver is ", testIsOver)
        end

        if not isOver and not testIsOver then
            if not isAutoTakeOutAICards then
                --isShowAutoTakeOutButton()
                --player logic ,disable
                if nextSeat == lordData.selfSeat_ and false then
                    LordUtil:clearRefind()
                    lordData.countDounTime = 15
                    --self.currentView_:displayCountDown(self.single_game_mgr.SELF, lordData.countDounTime)
                    local arrLastValues = lordData:getNeedBiggerCards(lordData.selfSeat_)
                    --手牌一张，需要大过的牌大于一张时直接Pass
                    local playerInfo = lordData:getPlayerInfo(lordData.selfSeat_)
                    if playerInfo and playerInfo.trust_ then
                        if playerInfo.cardCount_ == 1 and arrLastValues and #arrLastValues > 1 then
                            onFunction()
                            return
                        end
                    end

                    local gci = nil
                    if arrLastValues then
                        LordUtil:sortCards(arrLastValues)
                        gci = CardPattern:parseCards(arrLastValues)
                        if log_util.isDebug() == true then
                            log_util.i("lilc", "TakeOutCard,arr not nil, gci:type = ",gci.type,",value = ",gci.value,",length = ",gci.length)
                        end
                    else
                        gci = CardsInfo.new(CardPattern.ILLEGAL_CARDS, 0, 0)
                    end

                    --self.currentView_:setLastTakeOutCard(gci)
                    local canTakeOutOneHand = checkCanTakeOutOneHand()
                    if self.isAutoTakeOutLastCard_ or canTakeOutOneHand then
                        doAutoTakeOutLastCard(canTakeOutOneHand)
                    else
                        --self.currentView_:actionStateChange()
                    end
                else                   
                        local params = {}
                        params.lordSeat = lordData.lordSeat
                        params.seat = nextSeat
                        params.lastTakeOutSeat = seat
                        params.lastTakeOutCardGroup = takeOutCardGroup
                        if self.npcInfo_ then
                            params.npcId = self.npcInfo_.id
                        else
                            params.npcId = -1
                        end
                        params.isMess = isMess()
                        local nextTakeOutCardGroup = self.single_game_mgr:doTakeOutCard(params)
                        if nextTakeOutCardGroup and nextTakeOutCardGroup.cardList then
                            lordData:setCurHandFromCardObj(nextTakeOutCardGroup.cardList)
                        end
                        doTakeOutCard(nextTakeOutCardGroup, nextSeat)
                end
            end
        else
        	--game over
        	print('game over')
            local doResultParams = getResultParams()
            --doResult(doResultParams)
        end
    end
end

function getResultParams()
    local params = {}
    local lordData = getGameData()
    if lordData then
        local seat = lordData.currentOperaterSeat_ - 1
        if seat < 0 then
            seat = SingleGameManager.PRE
        end
        params.seat = seat
    end
    return params
end

function checkNPCIsSplitJoker(cardInfo, seat)
    --[[
        如果NPC拆王或者出四带二则直接判NPC输
        如果是路人拆王或者出四带二则判断是否是NPC叫的地主
        如果是NPC地主则玩家不扣分，路人扣分，NPC正常加分
        如果是玩家地主则正常扣分加分
    ]]
    local lordData = getGameData()
    local isOverForSplitJoker = false
    local pos = lordData:getPosBySeat(seat)
    if self.skillId_ == SingleGameConfig.NPC_SKILL_MUST_BOMB then
        local isSplitJokerover = false
        if pos ~= LordDef.PLAYER_POSITION_SELF then
            if cardInfo.type == CardPattern.SINGLE_CARD then
                if cardInfo.value == CardPoint.POINT_SMALL_JOKER or cardInfo.value == CardPoint.POINT_BIG_JOKER then
                    isSplitJokerover = true
                end
            elseif cardInfo.type == CardPattern.FOUR_WITH_TWO or cardInfo.type == CardPattern.FOUR_WITH_TWO_TWO then
                isSplitJokerover = true
            end
        end
    end
    return isSplitJokerover
end

function doNPCSplitJoker(seat)
    local isOverForSplitJoker = true
    local lordData = getGameData()
    if lordData then
        local splitJokerSeat = -1
        local pos = lordData:getPosBySeat(seat)
        if pos == LordDef.PLAYER_POSITION_PRE then
            splitJokerSeat = self.single_game_mgr.PRE
            if lordData.lordSeat == self.single_game_mgr.PRE or lordData.lordSeat == self.single_game_mgr.SELF then
                seat = self.single_game_mgr.SELF
            else
                seat = self.single_game_mgr.NEXT
            end
        elseif pos == LordDef.PLAYER_POSITION_NEXT then
            splitJokerSeat = self.single_game_mgr.NEXT
            if lordData.lordSeat == self.single_game_mgr.SELF or lordData.lordSeat == self.single_game_mgr.NEXT then
                seat = self.single_game_mgr.SELF
            else
                seat = self.single_game_mgr.PRE
            end
        end

        local doResultParams = {
                seat = seat,
                isOverForSplitJoker = isOverForSplitJoker,
                splitJokerSeat = splitJokerSeat
            }
        self:doResult(doResultParams)
    end
end

--[[--
    判断玩家首出的情况下手牌是否是一手不包含炸弹的牌，如果是则自动出牌
]]
function checkCanTakeOutOneHand()
    local selfHandCards = self.single_game_mgr:cloneCardsGroup(self.single_game_mgr:getSomeOneCards(self.single_game_mgr.SELF))
    local lastHadnCardGroup = self.single_game_mgr.lastTakeOutCardGroup
    local returnValue = false
    if lastHadnCardGroup and self.lastTakeOutCardGroupSeat_ ~= -1 and self.lastTakeOutCardGroupSeat_ ~= self.single_game_mgr.SELF then
        returnValue = false
    else
        LordUtil:sortCards(selfHandCards)
        local cardInfo = CardPattern:parseCards(selfHandCards)
        if self.skillId_ == SingleGameConfig.NPC_SKILL_MUST_BOMB then
            if cardInfo.type == CardPattern.FOUR_WITH_TWO or cardInfo.type == CardPattern.FOUR_WITH_TWO_TWO then
                return false
            elseif cardInfo.type == CardPattern.SINGLE_CARD and (cardInfo.value == CardPoint.POINT_SMALL_JOKER or cardInfo.value == CardPoint.POINT_BIG_JOKER) then
                return false
            end
        elseif self.skillId_ == SingleGameConfig.NPC_SKILL_NO_ROCKET then
            if cardInfo.type == CardPattern.DOUBLE_JOKER then
                return false
            end
        elseif self.skillId_ == SingleGameConfig.NPC_SKILL_NO_BOMB then
            if cardInfo.type == CardPattern.FOUR_CARDS then
                return false
            end
        elseif self.skillId_ == SingleGameConfig.NPC_SKILL_NO_THREECARD then
            if cardInfo.type == CardPattern.THREE_WITH_ONE or cardInfo.type == CardPattern.THREE_WITH_TWO or cardInfo.type == CardPattern.THREE_ONE_DRAGON or cardInfo.type == CardPattern.THREE_TWO_DRAGON or cardInfo.type == CardPattern.THREE_DRAGON then
                return false
            end
        elseif self.skillId_ == SingleGameConfig.NPC_SKILL_NO_LONG_STRIGHT then
            if cardInfo.type == CardPattern.SINGLE_DRAGON and cardInfo.length > 6 then
                return false
            end
        elseif self.skillId_ == SingleGameConfig.NPC_SKILL_NO_SPLIT_JOKER then
            if cardInfo.type == CardPattern.SINGLE_CARD and (cardInfo.value == CardPoint.POINT_SMALL_JOKER or cardInfo.value == CardPoint.POINT_BIG_JOKER) then
                return false
            end
        end
        if cardInfo.type > CardPattern.PASS and cardInfo.type <= CardPattern.THREE_TWO_DRAGON and cardInfo.type ~= CardPattern.FOUR_WITH_TWO and cardInfo.type ~= CardPattern.FOUR_WITH_TWO_TWO then
            LordUtil:sortCards(selfHandCards)
            if self.single_game_mgr:checkIsContainBomb(selfHandCards) then
                returnValue = false
            else
                returnValue = true
            end
        else
            returnValue = false
        end
    end
    return returnValue
end

function doAutoTakeOutLastCard(isTakeOutOneHand)
    local selfHandCards = self.single_game_mgr:getSomeOneCards(self.single_game_mgr.SELF)
    local takeOutCardList = {}
    local lastHadnCardGroup = self.single_game_mgr.lastTakeOutCardGroup
    local lordData = self:getGameData()
    if lordData then
        if lordData.currentOperaterSeat_ ~= lordData.selfSeat_ then
            self.isAutoTakeOutLastCard_ = true
        else
            if selfHandCards then
                    if log_util.isDebug() == true then
                        log_util.i(TAG, "doAutoTakeOutLastCard IN isTakeOutOneHand is ", isTakeOutOneHand)
                    end

                    local lastCard = isTakeOutOneHand and self.single_game_mgr:cloneCardsGroup(selfHandCards) or {selfHandCards[1]}
                    local cardInfo = CardPattern:parseCards(lastCard)
                    if lastHadnCardGroup and self.lastTakeOutCardGroupSeat_ ~= -1 and self.lastTakeOutCardGroupSeat_ ~= lordData.selfSeat_ then
                        if log_util.isDebug() == true then
                            log_util.i(TAG, "doAutoTakeOutLastCard IN first")
                        end

                        if lastHadnCardGroup.cardType == CardPattern.SINGLE_CARD then
                            if cardInfo then
                                if cardInfo.value > lastHadnCardGroup.cardValue then
                                    takeOutCardList = lastCard
                                    self.single_game_mgr:removeTakeoutCard(takeOutCardList, self.single_game_mgr.SELF)
                                    local takeOutCardGroup = {}
                                    takeOutCardGroup.cardList = takeOutCardList
                                    takeOutCardGroup.cardValue = cardInfo.value
                                    takeOutCardGroup.cardType = CardPattern.SINGLE_CARD
                                    self:doTakeOutCard(takeOutCardGroup, self.single_game_mgr.SELF)
                                else
                                    self:doTakeOutCard(nil, self.single_game_mgr.SELF)
                                end
                            end
                        else
                            self:doTakeOutCard(nil, self.single_game_mgr.SELF)
                        end
                    else
                        if log_util.isDebug() == true then
                            log_util.i(TAG, "doAutoTakeOutLastCard IN follow")
                        end

                        takeOutCardList = lastCard
                        self.single_game_mgr:removeTakeoutCard(takeOutCardList, self.single_game_mgr.SELF)
                        local takeOutCardGroup = {}
                        takeOutCardGroup.cardList = takeOutCardList
                        takeOutCardGroup.cardValue = cardInfo.value
                        takeOutCardGroup.cardType = cardInfo.type
                        doTakeOutCard(takeOutCardGroup, self.single_game_mgr.SELF)
                    end
            end    
        end
    end
end

init_game()
start_game()
startCallScore()

--[[
	单机斗地主嘻哈茶馆配置文件
]]

local SingleGameConfig = {}

-- 座位号
SingleGameConfig.SELF = 0
SingleGameConfig.NEXT = 1
SingleGameConfig.PRE = 2

-- NPC ID
SingleGameConfig.NPC_ID_CHILD = 1
SingleGameConfig.NPC_ID_UNCLE = 2
SingleGameConfig.NPC_ID_AUNT = 3
SingleGameConfig.NPC_ID_RUFFIAN_LIU = 4
SingleGameConfig.NPC_ID_MASTER = 5

-- NPC性格类型
SingleGameConfig.NPC_NATURE_TYPE_TROUBLE = 1 -- 捣乱型
SingleGameConfig.NPC_NATURE_TYPE_SAFE = 2 -- 保险型
SingleGameConfig.NPC_NATURE_TYPE_LIMIT = 3 -- 限制型
SingleGameConfig.NPC_NATURE_TYPE_CHEATER = 4 -- 老千型
SingleGameConfig.NPC_NATURE_TYPE_GAMBLER = 5 -- 赌徒型

-- NPC性格
SingleGameConfig.NPC_NATURE_CHILD = {SingleGameConfig.NPC_NATURE_TYPE_TROUBLE} -- 破小孩
SingleGameConfig.NPC_NATURE_UNCLE = {SingleGameConfig.NPC_NATURE_TYPE_SAFE} -- TAXI大叔
SingleGameConfig.NPC_NATURE_AUNT = {SingleGameConfig.NPC_NATURE_TYPE_LIMIT} -- 广场舞大婶
SingleGameConfig.NPC_NATURE_RUFFIAN_LIU = {SingleGameConfig.NPC_NATURE_TYPE_CHEATER, SingleGameConfig.NPC_NATURE_TYPE_GAMBLER} -- 大老刘

-- NPC技能
SingleGameConfig.NPC_SKILL_RANDOM_USER_CARD = 1 -- 乱序
SingleGameConfig.NPC_SKILL_ROB_LORD = 2 -- 抢地主
SingleGameConfig.NPC_SKILL_GIVE_LORD = 3 -- 让地主
SingleGameConfig.NPC_SKILL_TIME_LIMIT = 4 -- 限时
SingleGameConfig.NPC_SKILL_HIDE_CARD = 5 -- 隐藏
SingleGameConfig.NPC_SKILL_LUCKY_CARD = 6 -- 幸运之神

SingleGameConfig.NPC_SKILL_SIMPLE_BOMB = 7 -- 简炸
SingleGameConfig.NPC_SKILL_DOUBLE_SCORE = 8 -- 加倍
SingleGameConfig.NPC_SKILL_NO_DEDUCTION = 9 -- 幸运庇护
SingleGameConfig.NPC_SKILL_SED_STAR = 10 -- 悲剧之星

SingleGameConfig.NPC_SKILL_NO_BOMB = 11 -- 禁止炸弹
SingleGameConfig.NPC_SKILL_NO_ROCKET = 12 -- 禁止火箭
SingleGameConfig.NPC_SKILL_NO_THREECARD = 13 -- 禁止三带
SingleGameConfig.NPC_SKILL_NO_SPLIT_JOKER = 14 -- 禁止拆王
SingleGameConfig.NPC_SKILL_NO_LONG_STRIGHT = 15 -- 禁止长顺
SingleGameConfig.NPC_SKILL_RESTART = 16 -- 复盘

SingleGameConfig.NPC_SKILL_DISABLE_CARD = 17 -- 废牌
SingleGameConfig.NPC_SKILL_ALWAYS_BOMB = 18 -- 炸弹
SingleGameConfig.NPC_SKILL_GAMBLER_GOD = 19 -- 赌神庇护
SingleGameConfig.NPC_SKILL_WINNING_STREAK = 20 -- 连胜
SingleGameConfig.NPC_SKILL_THREECARD_BOMB = 21 -- 三张成炸
SingleGameConfig.NPC_SKILL_MUST_BOMB = 22 -- 炸弹火箭必炸

SingleGameConfig.NPC_NAME = {
	"豆豆",
	"孙叔",
	"赵婶",
	"大老刘",
	"茶馆主人",
}

SingleGameConfig.NPC_SKILL_NAME = {
	"乱序",
	"抢地主",
	"让地主",
	"限时",
	"隐藏",
	"幸运之神",
	"简炸",
	"加倍",
	"幸运庇护",
	"悲剧之星",
	"禁止炸弹",
	"禁止火箭",
	"禁止三带",
	"禁止拆王",
	"禁止长顺",
	"复盘",
	"废牌",
	"炸弹",
	"赌神庇护",
	"连胜",
	"三张成炸",
	"炸弹必出",
}

SingleGameConfig.NPC_SKILL_INFO = {
	"本局你的手牌将被打乱！",
	"本局小孩抢到了地主，同时您无法看到他的底牌哦~",
	"本局您被指定为地主，加油！",
	"咱玩一把快牌吧（15秒内出牌）！",
	"都不报手牌数，你还能打好牌么？",
	"小孩被幸运之神附身了，看起来牌不错哦！",
	"本局内炸弹所有都不会加倍，看来输赢不会太大哦！",
	"本局您输掉的分数将加倍，一定要努力获胜啊！",
	"本局您胜利将不加分，输了依然会扣分哦！",
	"您被悲剧之星附体了，这副牌可真悲剧啊！",
	"本局您不能使用炸弹，选择别的牌型取胜吧！",
	"本局您不能使用火箭，选择别的牌型取胜吧！",
	"本局您不能使用任何三带牌型，选择别的牌型取胜吧！",
	"本局您手中的双王不能拆开使用，勇敢的用火箭加倍吧！",
	"本局您不能使用任何大于6张的顺子牌型，看来长顺要悲剧喽！",
	"",
	"本局中双王和一张2定为废牌，不会出现在本局中哦！",
	"本局大老刘手中必有一个炸弹，一定要小心哦！",
	"本局大老刘获胜分数加倍，输了不扣分，太无赖啦！",
	"",
	"当大老刘连续获胜时，下一局获胜分数将翻倍，赶紧终止他连胜！",
	"炸就要炸个痛快！ 炸弹火箭必出，不许带不许拆！"
}

SingleGameConfig.NO_SKILL_PERCENT = 30

-- 破小孩
SingleGameConfig.NPC_CHILD = {
	id = SingleGameConfig.NPC_ID_CHILD,
	name = SingleGameConfig.NPC_NAME[SingleGameConfig.NPC_ID_CHILD],
	skills = {
		normal = {
			{skillId = SingleGameConfig.NPC_SKILL_RANDOM_USER_CARD, percentRange = {min = SingleGameConfig.NO_SKILL_PERCENT + 1, max = 70}},
			{skillId = SingleGameConfig.NPC_SKILL_HIDE_CARD, percentRange = {min = 71, max = 100}},
		},
		special = {
		},
		specialLevel = 3
	},
	dialogContentText = {
		"豆豆斗地主，铜板有没有！",
		"我今年五岁了，过年就四岁了(≧▽≦)/。",
		"我是茶馆小主人，不差钱呐！"
	},
	matchInfo = {
		"连胜【豆豆】有免费铜板拿噢。多胜多得，亲，加油↖(^ω^)↗！"
	},
	unlockCondition = "",
	pacerText = "【%s拉豆豆（陪打员）助阵，要小心哦！】",
	nature = SingleGameConfig.NPC_NATURE_CHILD,
	victorAward = {2, 4, 8, 15, 30, 60, 100, 200, 350, 600}
}

-- TAXI大叔
SingleGameConfig.NPC_UNCLE = {
	id = SingleGameConfig.NPC_ID_UNCLE,
	name = SingleGameConfig.NPC_NAME[SingleGameConfig.NPC_ID_UNCLE],
	skills = {
		normal = {
			{skillId = SingleGameConfig.NPC_SKILL_TIME_LIMIT, percentRange = {min = SingleGameConfig.NO_SKILL_PERCENT + 1, max = 60}},
			{skillId = SingleGameConfig.NPC_SKILL_NO_ROCKET, percentRange = {min = 61, max = 80}},
			{skillId = SingleGameConfig.NPC_SKILL_HIDE_CARD, percentRange = {min = 81, max = 100}},
		},
		special = {
		},
		specialLevel = 3
	},
	dialogContentText = {
		"别赢我太多哦，回家媳妇该骂我了。",
		"小赌怡情，俺也怡一下情！",
		"今天天气不错，要不要玩两手！",
		"斗地主就是要享受追求的过程，忽略成败得失，偶尔也“难得糊涂”呐！",
		"人生如牌，不管好牌坏牌，既不要得意忘形，也不要怨天尤人。",
	},
	matchInfo = {
		"打立【孙叔】就是把孙叔的钱统统的赢过来。亲，看好你噢！"
	},
	unlockText = "%s，#我#关#注#你#好#久#了#，#一#会#儿#也#来#找#我#玩#两#把#吧#！",
	unlockCondition = "需要等级：%d",
	pacerText = "【%s拉孙叔（陪打员）助阵，要小心哦！】",
	nature = SingleGameConfig.NPC_NATURE_UNCLE
}

-- 广场舞大婶
SingleGameConfig.NPC_AUNT = {
	id = SingleGameConfig.NPC_ID_AUNT,
	name = SingleGameConfig.NPC_NAME[SingleGameConfig.NPC_ID_AUNT],
	skills = {
		normal = {
			{skillId = SingleGameConfig.NPC_SKILL_RANDOM_USER_CARD, percentRange = {min = SingleGameConfig.NO_SKILL_PERCENT + 1, max = 50}},
			{skillId = SingleGameConfig.NPC_SKILL_NO_BOMB, percentRange = {min = 51, max = 60}},
			{skillId = SingleGameConfig.NPC_SKILL_NO_THREECARD, percentRange = {min = 61, max = 80}},
			{skillId = SingleGameConfig.NPC_SKILL_HIDE_CARD, percentRange = {min = 81, max = 100}},
		},
		special = {
		},
		specialLevel = 3
	},
	dialogContentText = {
		"无论你多会记牌、打牌，都抵不过人家手中的一把好牌噢。",
		"广场舞out了，斗地主才是王道呢！",
		"玩牌的心态很重要，千万不要和你的牌友争吵。",
		"记牌，即是记忆力的大比拼，更是实力的证明哦。",
	},
	matchInfo = {
		"打立【赵婶】就是把赵婶的钱统统的赢过来。亲，看好你噢！"
	},
	unlockText = "%s，#我#关#注#你#好#久#了#，#一#会#儿#也#来#找#我#玩#两#把#吧#！",
	unlockCondition = "需要等级：%d",
	pacerText = "【%s拉赵婶（陪打员）助阵，要小心哦！】",
	nature = SingleGameConfig.NPC_NATURE_AUNT
}

-- 大老刘
SingleGameConfig.NPC_RUFFIAN_LIU = {
	id = SingleGameConfig.NPC_ID_RUFFIAN_LIU,
	name = SingleGameConfig.NPC_NAME[SingleGameConfig.NPC_ID_RUFFIAN_LIU],
	skills = {
		normal = {
			{skillId = SingleGameConfig.NPC_SKILL_RANDOM_USER_CARD, percentRange = {min = SingleGameConfig.NO_SKILL_PERCENT + 1, max = 40}},
			{skillId = SingleGameConfig.NPC_SKILL_TIME_LIMIT, percentRange = {min = 41, max = 50}},
			{skillId = SingleGameConfig.NPC_SKILL_HIDE_CARD, percentRange = {min = 51, max = 70}},
			{skillId = SingleGameConfig.NPC_SKILL_DISABLE_CARD, percentRange = {min = 71, max = 90}},
			{skillId = SingleGameConfig.NPC_SKILL_MUST_BOMB, percentRange = {min = 91, max = 100}},
		},
		special = {
		},
		condition = {
		},
		specialLevel = 3
	},
	dialogContentText = {
		"高手过招，赢者胜。",
		"水平高不高，赢了我才知道。",
		"小王一出，基本会被大王拍死。所以说，老大在，老二最好不要出声！",
		"教你一手：示敌以弱，诱使对方炸你一手！",
		"教你一手： 识清时务 不要盲目叫牌",
	},
	matchInfo = {
		"打立【大老刘】就是把大老刘的钱统统的赢过来。亲，看好你噢！"
	},
	unlockText = "%s，#我#关#注#你#好#久#了#，#一#会#儿#也#来#找#我#玩#两#把#吧#！",
	unlockCondition = "需要等级：%d",
	pacerText = "【%s拉大老刘（陪打员）助阵，要小心哦！】",
	nature = SingleGameConfig.NPC_NATURE_RUFFIAN_LIU
}

-- 茶馆主人
SingleGameConfig.NPC_MASTER = {
	id = SingleGameConfig.NPC_ID_MASTER,
	name = SingleGameConfig.NPC_NAME[SingleGameConfig.NPC_ID_MASTER],
	skills = {
	},
	dialogContentText = {
		"残局是高手间的对决，你不准备来试试身手？",
		"我经营茶馆几十年了，可收集了不少的残局哦！"
	},
	matchInfo = {
		"解#锁#一#个#残#局#，#茶#馆#主#人#奖#励#你#200#茶#钿#。#"
	},
	unlockText = "%s，#我#关#注#你#好#久#了#，#一#会#儿#也#来#找#我#玩#两#把#吧#！",
	unlockCondition = "需要等级：%d",
	pacerText = "【%s拉茶馆主人（陪打员）助阵，要小心哦！】",
}

SingleGameConfig.NPC = {
	SingleGameConfig.NPC_CHILD,
	SingleGameConfig.NPC_UNCLE,
	SingleGameConfig.NPC_AUNT,
	SingleGameConfig.NPC_RUFFIAN_LIU,
	SingleGameConfig.NPC_MASTER,
}

-- 破小孩不同级别对应的比赛信息
SingleGameConfig.NPC_CHILD_MATCHINFO = {
	{
		level = 1, 
		matchId = 3,
		matchName = "连胜挑战桌",
		signupCost = 0,
		initialchip = 1000,
		baseScore = 10,
		winExp = 10,
		loseExp = 1,
		awardInfo = {
			{
				wincount = 5,
				exp = 20,
				copper = 100
			},
		}
	},
}

-- TAXI大叔不同级别对应的比赛信息
SingleGameConfig.NPC_UNCLE_MATCHINFO = {
	{
		level = 1, 
		matchId = 3,
		matchName = "1000铜板挑战桌",
		signupCost = 1000,
		initialchip = 1000,
		baseScore = 20,
		winExp = 20,
		loseExp = 2,
		awardInfo = {
			{
				wincount = 0,
				exp = 100,
				copper = 500
			},
		}
	},
}

-- 广场舞大婶不同级别对应的比赛信息
SingleGameConfig.NPC_AUNT_MATCHINFO = {
	{
		level = 1, 
		matchId = 3,
		matchName = "2000铜板挑战桌",
		signupCost = 5000,
		initialchip = 6000,
		baseScore = 100,
		winExp = 100,
		loseExp = 10,
		awardInfo = {
			{
				wincount = 0,
				exp = 200,
				copper = 2000
			},
		}
	},
}

-- 大老刘不同级别对应的比赛信息
SingleGameConfig.NPC_LIU_MATCHINFO = {
	{
		level = 1, 
		matchId = 3,
		matchName = "10000铜板挑战桌",
		signupCost = 20000,
		initialchip = 40000,
		baseScore = 500,
		winExp = 400,
		loseExp = 40,
		awardInfo = {
			{
				wincount = 0,
				exp = 500,
				copper = 5000
			},
		}
	},
}

SingleGameConfig.NPC_MASTER_MATCHINFO = {
	{
		matchName = "残局游戏",
		awardInfo = {
			{
				wincount = 0,
				exp = 100,
				copper = 100
			},
		}
	},
}

SingleGameConfig.NPC_MATCHINFO = {
	SingleGameConfig.NPC_CHILD_MATCHINFO,
	SingleGameConfig.NPC_UNCLE_MATCHINFO,
	SingleGameConfig.NPC_AUNT_MATCHINFO,
	SingleGameConfig.NPC_LIU_MATCHINFO,
	SingleGameConfig.NPC_MASTER_MATCHINFO
}

SingleGameConfig.MATCH_TYPE_CUSTOM = 1
SingleGameConfig.MATCH_TYPE_ISLAND = 2

SingleGameConfig.messConfigData = {
	{
		id = 1,
		isLocked = false,
		selfCardInt = {4, 5, 5, 5, 6, 7, 7, 7, 8, 9, 10, 11, 12, 13, 13, 15, 16},
		preCardInt = {6, 6, 8, 9, 10, 11, 12, 13, 14, 15},
		nextCardInt = {7, 8, 8, 17},
		answers = {
			{seat = 0, takeOutCards = {8, 9, 10, 11, 12}}, 
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {9, 10, 11, 12, 13}},
			{seat = 0, takeOutCards = {}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {8}},
			{seat = 0, takeOutCards = {15}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {5, 5, 5, 4}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {7, 7, 7, 6}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {13, 13}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {16}}
		},
		starLevelCondition = {
			costTime = 25,
		},
		starLevelInfo = {
			"30秒内完成",
			"25秒内完成"
		},
		answerCost = 5000,
		starLevel = 0,
		defaultLevel = 1,
		awardCopper = 100
	},
	{
		id = 2,
		isLocked = true,
		selfCardInt = {6, 6, 7, 8, 9, 9, 10, 11, 11, 12, 12, 14, 14, 14, 14},
		preCardInt = {4, 4, 5, 7, 7, 9, 9, 10, 10, 10, 12, 13, 13},
		nextCardInt = {13},
		answers = {
			{seat = 0, takeOutCards = {6, 6}}, 
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {7, 7}},
			{seat = 0, takeOutCards = {12, 12}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {13, 13}},
			{seat = 0, takeOutCards = {}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {10, 10, 10, 4, 4}},
			{seat = 0, takeOutCards = {}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {5}},
			{seat = 0, takeOutCards = {14}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {7, 8, 9, 10, 11}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {14, 14, 14, 9}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {11}},
		},
		starLevelCondition = {
			costTime = 25,
		},
		starLevelInfo = {
			"30秒内完成",
			"25秒内完成"
		},
		answerCost = 5000,
		starLevel = 0,
		defaultLevel = 1,
		awardCopper = 100
	},
	{
		id = 3,
		isLocked = true,
		selfCardInt = {7, 8, 8, 8, 10, 10, 10, 15, 15, 16},
		preCardInt = {11, 11, 12, 12, 13, 13},
		nextCardInt = {10, 12, 13, 13, 14, 14, 14, 17},
		answers = {
			{seat = 0, takeOutCards = {8, 8, 8}}, 
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {16}},
			{seat = 1, takeOutCards = {17}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {}},
			{seat = 1, takeOutCards = {14, 14, 14, 10}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {}},
			{seat = 1, takeOutCards = {12}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {15}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {15}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {10, 10, 10, 7}},
		},
		starLevelCondition = {
			lastHandType = 1
		},
		starLevelInfo = {
			"30秒内完成",
			"最后一手牌为单张"
		},
		answerCost = 50000,
		starLevel = 0,
		defaultLevel = 2,
		awardCopper = 300
	},
	{
		id = 4,
		isLocked = true,
		selfCardInt = {3, 4, 5, 6, 7, 8, 8, 9, 9, 9, 10, 10, 10, 14, 14, 15},
		preCardInt = {3, 4, 4, 5, 5, 6, 11, 11, 11, 12, 12, 12, 13, 13, 13, 14, 14},
		nextCardInt = {12, 13, 17},
		answers = {
			{seat = 0, takeOutCards = {3, 4, 5, 6, 7, 8}}, 
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {14, 14}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {9, 9, 9, 10, 10, 10, 15, 8}},
		},
		starLevelCondition = {
			takeOutCardCount = 0,
		},
		starLevelInfo = {
			"30秒内完成",
			"对手未出牌"
		},
		answerCost = 50000,
		starLevel = 0,
		defaultLevel = 2,
		awardCopper = 300
	},
	{
		id = 5,
		isLocked = true,
		selfCardInt = {3, 3, 3, 6, 7, 8, 8, 10, 10},
		preCardInt = {3, 4, 4, 4, 5, 7},
		nextCardInt = {6, 7, 8, 8, 15, 15},
		answers = {
			{seat = 0, takeOutCards = {7}}, 
			{seat = 1, takeOutCards = {8}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {10}},
			{seat = 1, takeOutCards = {15}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {}},
			{seat = 1, takeOutCards = {6}},
			{seat = 2, takeOutCards = {7}},
			{seat = 0, takeOutCards = {8}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {3, 3, 3}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {4, 4, 4}},
			{seat = 0, takeOutCards = {}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {3}},
			{seat = 0, takeOutCards = {8}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {6}},
			{seat = 1, takeOutCards = {7}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {10}},
		},
		starLevelCondition = {
			takeOutCardCount = 0,
		},
		starLevelInfo = {
			"30秒内完成",
			"对手未出牌"
		},
		answerCost = 500000,
		starLevel = 0,
		defaultLevel = 3,
		awardCopper = 800
	},
	{
		id = 6,
		isLocked = true,
		selfCardInt = {5,5,7,8,9,10,11,12,13,17},
		preCardInt = {4,8,9,9,9,10,11,12,13,14},
		nextCardInt = {13},
		answers = {
			{seat = 0, takeOutCards = {7, 8, 9, 10, 11, 12}}, 
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {8, 9, 10, 11, 12, 13}},
			{seat = 0, takeOutCards = {}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {4}},
			{seat = 0, takeOutCards = {13}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {14}},
			{seat = 0, takeOutCards = {17}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {5, 5}},
		},
		starLevelCondition = {
			takeOutCardCount = 0,
		},
		starLevelInfo = {
			"30秒内完成",
			"对手未出牌"
		},
		answerCost = 5000,
		starLevel = 0,
		defaultLevel = 1,
		awardCopper = 100
	},
	{
		id = 7,
		isLocked = true,
		selfCardInt = {3,3,3,6,8,8,9,10,11,12,13,14,14,14,15,15},
		preCardInt = {7,8,13,13,13,16,17},
		nextCardInt = {4,4,7,8,9,10,11,12,12,12},
		answers = {
			{seat = 0, takeOutCards = {8, 9, 10, 11, 12, 13}}, 
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {15, 15}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {16, 17}},
			{seat = 0, takeOutCards = {}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {13, 13, 13}},
			{seat = 0, takeOutCards = {}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {8}},
			{seat = 0, takeOutCards = {14}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {8}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {14, 14}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {3, 3, 3, 6}},
		},
		starLevelCondition = {
			takeOutCardCount = 0,
		},
		starLevelInfo = {
			"30秒内完成",
			"对手未出牌"
		},
		answerCost = 5000,
		starLevel = 0,
		defaultLevel = 1,
		awardCopper = 100
	},
	{
		id = 8,
		isLocked = true,
		selfCardInt = {3,3,3,4,5,6,7,7,8,9,10,11,13,14,14,15,15,15,15},
		preCardInt = {6,6,6,9,10,11,12,13,13,17},
		nextCardInt = {7,8,9,10,11,12,13,14,14},
		answers = {
			{seat = 0, takeOutCards = {3, 4, 5, 6, 7, 8, 9, 10, 11}}, 
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {14, 14}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {15, 15, 15, 15, 7, 13}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {3, 3}},
		},
		starLevelCondition = {
			takeOutCardCount = 0,
		},
		starLevelInfo = {
			"30秒内完成",
			"对手未出牌"
		},
		answerCost = 50000,
		starLevel = 0,
		defaultLevel = 2,
		awardCopper = 300
	},
	{
		id = 9,
		isLocked = true,
		selfCardInt = {7, 7, 7, 8, 9, 10, 11, 12, 13, 15, 15},
		preCardInt = {5, 5, 6, 6, 14, 14, 14},
		nextCardInt = {4, 6, 7, 8, 9, 9, 10, 10, 11, 12, 13, 14, 15, 15, 17},
		answers = {
			{seat = 0, takeOutCards = {7, 7, 7, 8}}, 
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {14, 14, 14, 5}},
			{seat = 0, takeOutCards = {}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {5}},
			{seat = 0, takeOutCards = {15}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {9, 10, 11, 12, 13}},
			{seat = 1, takeOutCards = {10, 11, 12, 13, 14}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {}},
			{seat = 1, takeOutCards = {6, 7, 8, 9, 10}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {}},
			{seat = 1, takeOutCards = {15, 15}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {}},
			{seat = 1, takeOutCards = {4}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {15}},
		},
		starLevelCondition = {
			takeOutCardCount = 0,
		},
		starLevelInfo = {
			"30秒内完成",
			"对手未出牌"
		},
		answerCost = 50000,
		starLevel = 0,
		defaultLevel = 2,
		awardCopper = 300
	},
	{
		id = 10,
		isLocked = true,
		selfCardInt = {4, 4, 6, 6, 7, 8, 9, 10, 11, 12, 13, 13, 15},
		preCardInt = {7, 8, 9, 10, 11, 12, 13, 14, 14},
		nextCardInt = {4},
		answers = {
			{seat = 0, takeOutCards = {13}}, 
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {6}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {7, 8, 9, 10, 11, 12, 13}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {6}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {13}},
			{seat = 0, takeOutCards = {15}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {4, 4}},
		},
		starLevelCondition = {
			takeOutCardCount = 0,
		},
		starLevelInfo = {
			"30秒内完成",
			"对手未出牌"
		},
		answerCost = 500000,
		starLevel = 0,
		defaultLevel = 3,
		awardCopper = 800
	},
	{
		id = 11,
		isLocked = true,
		selfCardInt = {5, 5, 6, 6, 6, 7, 8, 9, 10, 11, 12, 12, 12, 15},
		preCardInt = {4, 4, 8, 8, 8, 13, 15},
		nextCardInt = {3, 3, 3, 4, 4, 7, 9, 10, 11, 12, 13, 13, 13, 14, 15},
		answers = {
			{seat = 0, takeOutCards = {6, 6}}, 
			{seat = 1, takeOutCards = {13, 13}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {}},
			{seat = 1, takeOutCards = {3, 3, 3, 7}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {12, 12, 12, 5}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {15}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {5, 6, 7, 8, 9, 10, 11}},
		},
		starLevelCondition = {
			takeOutCardCount = 0,
		},
		starLevelInfo = {
			"30秒内完成",
			"对手未出牌"
		},
		answerCost = 5000,
		starLevel = 0,
		defaultLevel = 1,
		awardCopper = 100
	},
	{
		id = 12,
		isLocked = true,
		selfCardInt = {5, 5, 8, 8, 9, 9, 12, 16, 17},
		preCardInt = {5, 5, 6, 6, 10, 10, 11, 15, 15},
		nextCardInt = {7, 7},
		answers = {
			{seat = 0, takeOutCards = {5}}, 
			{seat = 1, takeOutCards = {7}},
			{seat = 2, takeOutCards = {11}},
			{seat = 0, takeOutCards = {12}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {15}},
			{seat = 0, takeOutCards = {16}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {8, 8}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {10, 10}},
			{seat = 0, takeOutCards = {}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {5, 5}},
			{seat = 0, takeOutCards = {9, 9}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {17}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {5}},
		},
		starLevelCondition = {
			takeOutCardCount = 0,
		},
		starLevelInfo = {
			"30秒内完成",
			"对手未出牌"
		},
		answerCost = 5000,
		starLevel = 0,
		defaultLevel = 1,
		awardCopper = 100
	},
	{
		id = 13,
		isLocked = true,
		selfCardInt = {3, 3, 3, 5, 6, 6, 6, 8, 9, 9, 10, 11, 12, 13, 15, 15, 15, 16},
		preCardInt = {7, 8, 9, 10, 11, 12, 13, 14},
		nextCardInt = {4, 4, 4, 4, 5, 5, 5, 6, 13},
		answers = {
			{seat = 0, takeOutCards = {6, 6, 6, 5}}, 
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {8, 9, 10, 11, 12}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {9, 10, 11, 12, 13}},
			{seat = 0, takeOutCards = {}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {7}},
			{seat = 0, takeOutCards = {16}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {3, 3, 3, 9}},
			{seat = 1, takeOutCards = {5, 5, 5, 6}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {15, 15, 15, 13}},
		},
		starLevelCondition = {
			takeOutCardCount = 0,
		},
		starLevelInfo = {
			"30秒内完成",
			"对手未出牌"
		},
		answerCost = 50000,
		starLevel = 0,
		defaultLevel = 2,
		awardCopper = 300
	},
	{
		id = 14,
		isLocked = true,
		selfCardInt = {7, 7, 8, 8, 8, 9, 9, 11, 11, 11, 11, 14, 14},
		preCardInt = {3, 3, 4, 4, 5, 5, 13, 13, 15, 15},
		nextCardInt = {3, 4, 5, 6, 6, 7, 10, 10, 10, 10},
		answers = {
			{seat = 0, takeOutCards = {8}}, 
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {13}},
			{seat = 0, takeOutCards = {14}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {15}},
			{seat = 0, takeOutCards = {}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {3, 3}},
			{seat = 0, takeOutCards = {7, 7}},
			{seat = 1, takeOutCards = {10, 10}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {11, 11}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {8, 8}},
			{seat = 1, takeOutCards = {10, 10}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {11, 11}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {9, 9}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {14}},
		},
		starLevelCondition = {
			takeOutCardCount = 0,
		},
		starLevelInfo = {
			"30秒内完成",
			"对手未出牌"
		},
		answerCost = 50000,
		starLevel = 0,
		defaultLevel = 2,
		awardCopper = 300
	},
	{
		id = 15,
		isLocked = true,
		selfCardInt = {3, 4, 5, 5, 7, 7},
		preCardInt = {3},
		nextCardInt = {3, 4, 5, 5, 15, 15},
		answers = {
			{seat = 0, takeOutCards = {5}}, 
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {4}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {7, 7}},
			{seat = 1, takeOutCards = {15, 15}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {}},
			{seat = 1, takeOutCards = {5, 5}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {}},
			{seat = 1, takeOutCards = {3}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {5}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {3}},
		},
		starLevelCondition = {
			takeOutCardCount = 0,
		},
		starLevelInfo = {
			"30秒内完成",
			"对手未出牌"
		},
		answerCost = 500000,
		starLevel = 0,
		defaultLevel = 3,
		awardCopper = 800
	},
	{
		id = 16,
		isLocked = true,
		selfCardInt = {7, 7, 7, 8, 8, 9, 9, 9, 10, 10, 11, 11, 12, 15, 15, 16},
		preCardInt = {8, 11, 12, 14, 14, 14, 17},
		nextCardInt = {9, 10, 11, 12, 13, 14, 15, 15},
		answers = {
			{seat = 0, takeOutCards = {12}}, 
			{seat = 1, takeOutCards = {14}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {16}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {17}},
			{seat = 0, takeOutCards = {}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {14, 14, 14, 8}},
			{seat = 0, takeOutCards = {}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {11}},
			{seat = 0, takeOutCards = {15}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {7, 7, 7, 8, 8}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {9, 9, 9, 10, 10}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {15}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {11, 11}},
		},
		starLevelCondition = {
			takeOutCardCount = 0,
		},
		starLevelInfo = {
			"30秒内完成",
			"对手未出牌"
		},
		answerCost = 5000,
		starLevel = 0,
		defaultLevel = 1,
		awardCopper = 100
	},
	{
		id = 17,
		isLocked = true,
		selfCardInt = {7, 7, 7, 8, 11, 11, 11, 14},
		preCardInt = {10, 13, 15, 15, 15},
		nextCardInt = {10, 10, 11, 12, 13, 14},
		answers = {
			{seat = 0, takeOutCards = {7, 7, 7}}, 
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {11, 11, 11}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {15, 15, 15}},
			{seat = 0, takeOutCards = {}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {10}},
			{seat = 0, takeOutCards = {14}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {8}},
		},
		starLevelCondition = {
			takeOutCardCount = 0,
		},
		starLevelInfo = {
			"30秒内完成",
			"对手未出牌"
		},
		answerCost = 5000,
		starLevel = 0,
		defaultLevel = 1,
		awardCopper = 100
	},
	{
		id = 18,
		isLocked = true,
		selfCardInt = {9, 11, 11, 15, 15, 15, 15},
		preCardInt = {12, 12},
		nextCardInt = {12, 13, 16, 17},
		answers = {
			{seat = 0, takeOutCards = {15, 15, 15, 11, 11}}, 
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {9}},
			{seat = 1, takeOutCards = {12}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {15}},
		},
		starLevelCondition = {
			takeOutCardCount = 0,
		},
		starLevelInfo = {
			"30秒内完成",
			"对手未出牌"
		},
		answerCost = 50000,
		starLevel = 0,
		defaultLevel = 2,
		awardCopper = 300
	},
	{
		id = 19,
		isLocked = true,
		selfCardInt = {3, 3, 4, 4, 4, 4, 5, 5, 6, 7, 8, 9, 10, 15, 15, 15},
		preCardInt = {7, 8, 9, 10, 11, 12, 13, 14, 15},
		nextCardInt = {9, 11, 11, 13, 13, 16, 17},
		answers = {
			{seat = 0, takeOutCards = {6, 7, 8, 9, 10}}, 
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {7, 8, 9, 10, 11}},
			{seat = 0, takeOutCards = {}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {12}},
			{seat = 0, takeOutCards = {15}},
			{seat = 1, takeOutCards = {16}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {4, 4, 4, 4}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {3, 3}},
			{seat = 1, takeOutCards = {11, 11}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {15, 15}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {5, 5}},
		},
		starLevelCondition = {
			takeOutCardCount = 0,
		},
		starLevelInfo = {
			"30秒内完成",
			"对手未出牌"
		},
		answerCost = 50000,
		starLevel = 0,
		defaultLevel = 2,
		awardCopper = 300
	},
	{
		id = 20,
		isLocked = true,
		selfCardInt = {5, 6, 7, 7, 7, 8, 8, 8, 8, 9, 10, 11, 12, 12, 12, 13, 15, 15, 16, 17},
		preCardInt = {3, 3, 3, 3, 9, 9, 9, 10, 11, 11, 12, 13, 14},
		nextCardInt = {4, 5, 5, 5, 6, 6, 6, 10, 10, 14, 14, 14, 15, 15},
		answers = {
			{seat = 0, takeOutCards = {7, 7, 7, 8, 8, 8, 5, 6}}, 
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {3, 3, 3, 3}},
			{seat = 0, takeOutCards = {}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {10, 11, 12, 13, 14}},
			{seat = 0, takeOutCards = {16, 17}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {8, 9, 10, 11, 12, 13}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {15, 15}},
			{seat = 1, takeOutCards = {}},
			{seat = 2, takeOutCards = {}},
			{seat = 0, takeOutCards = {12, 12}},
		},
		starLevelCondition = {
			takeOutCardCount = 0,
		},
		starLevelInfo = {
			"30秒内完成",
			"对手未出牌"
		},
		answerCost = 500000,
		starLevel = 0,
		defaultLevel = 3,
		awardCopper = 800
	},
}

SingleGameConfig.NPC_RUFFIAN_LIU_BASE_SCORE_LEVEL = {
	500,
	1000,
	5000,
	10000,
	50000,
	100000,
	500000,
	1000000,
	5000000,
	10000000
}

SingleGameConfig.jjMatchLevel = {
	{
		signupCost = 100,
		gameCount = 5,
		baseScore = 100,
		initialchip = 0,
		matchId = 2,
		award = {
			{exp = 100},
			{exp = 50},
			{exp = 30}
		}
	},
	{
		signupCost = 200,
		gameCount = 5,
		baseScore = 100,
		initialchip = 0,
		matchId = 2,
		award = {
			{exp = 100},
			{exp = 50},
			{exp = 30}
		}
	},
	{
		signupCost = 500,
		gameCount = 5,
		baseScore = 100,
		initialchip = 0,
		matchId = 2,
		award = {
			{exp = 100},
			{exp = 50},
			{exp = 30}
		}
	},
	{
		signupCost = 1000,
		gameCount = 5,
		baseScore = 100,
		initialchip = 0,
		matchId = 2,
		award = {
			{exp = 100},
			{exp = 50},
			{exp = 30}
		}
	},
	{
		signupCost = 2000,
		gameCount = 5,
		baseScore = 100,
		initialchip = 0,
		matchId = 2,
		award = {
			{exp = 100},
			{exp = 50},
			{exp = 30}
		}
	},
	{
		signupCost = 5000,
		gameCount = 8,
		baseScore = 100,
		initialchip = 0,
		matchId = 4,
		award = {
			{exp = 150},
			{exp = 80},
			{exp = 30}
		}
	},
	{
		signupCost = 10000,
		gameCount = 8,
		baseScore = 100,
		initialchip = 0,
		matchId = 4,
		award = {
			{exp = 150},
			{exp = 80},
			{exp = 30}
		}
	},
	{
		signupCost = 20000,
		gameCount = 8,
		baseScore = 100,
		initialchip = 0,
		matchId = 4,
		award = {
			{exp = 150},
			{exp = 80},
			{exp = 30}
		}
	},
	{
		signupCost = 50000,
		gameCount = 8,
		baseScore = 100,
		initialchip = 0,
		matchId = 4,
		award = {
			{exp = 150},
			{exp = 80},
			{exp = 30}
		}
	},
	{
		signupCost = 100000,
		gameCount = 8,
		baseScore = 100,
		initialchip = 0,
		matchId = 4,
		award = {
			{exp = 150},
			{exp = 80},
			{exp = 30}
		}
	},
	{
		signupCost = 200000,
		gameCount = 8,
		baseScore = 100,
		initialchip = 0,
		matchId = 4,
		award = {
			{exp = 150},
			{exp = 80},
			{exp = 30}
		}
	},
	{
		signupCost = 500000,
		gameCount = 8,
		baseScore = 100,
		initialchip = 0,
		matchId = 4,
		award = {
			{exp = 150},
			{exp = 80},
			{exp = 30}
		}
	},
}

SingleGameConfig.jjMatchPlayers = {
	{
		playerId = 1,
		playerName = "至尊A黑仔88",
		playerInfo = "精于计算在关键时刻诱导对手犯错，成功拿下第一届全国锦标赛冠军。",
		bestRankInfo = "第一届全国锦标赛冠军",
		icon = "img/lordsinglexhcg/jjmatch/player_%d_icon.png"
	},
	{
		playerId = 2,
		playerName = "风云_李秀岩",
		playerInfo = "打牌严谨风格多变，针对不同的对手有不同的策略。",
		bestRankInfo = "第一届全国锦标赛亚军",
		icon = "img/lordsinglexhcg/jjmatch/player_%d_icon.png"
	},
	{
		playerId = 3,
		playerName = "◥◣刺客◢◤",
		playerInfo = "敢打敢拼喜欢叫3分做地主，思维缜密出牌速度极快。",
		bestRankInfo = "第一届全国锦标赛季军",
		icon = "img/lordsinglexhcg/jjmatch/player_%d_icon.png"
	},
	{
		playerId = 4,
		playerName = "倾城乄醉",
		playerInfo = "凭借精湛的牌技成为了第一位“双败淘汰赛”赛制打牌副数大满贯的冠军。",
		bestRankInfo = "第二届全国锦标赛冠军",
		icon = "img/lordsinglexhcg/jjmatch/player_%d_icon.png"
	},
	{
		playerId = 5,
		playerName = "◥◣斗斗斗斗◢◤",
		playerInfo = "拥有超长的牌龄，沉稳的牌风，丰富的比赛经验于一身的高手。",
		bestRankInfo = "第二届全国锦标赛季军",
		icon = "img/lordsinglexhcg/jjmatch/player_%d_icon.png"
	},
	{
		playerId = 6,
		playerName = "潇洒斗！！",
		playerInfo = "记牌能力超强，给对手造成牌被看穿的感觉，和他对阵压力很大。",
		bestRankInfo = "第三届全国锦标赛冠军",
		icon = "img/lordsinglexhcg/jjmatch/player_%d_icon.png"
	},
	{
		playerId = 7,
		playerName = "今天你掘开了吗",
		playerInfo = "1届个人全国锦标赛冠军，2届团体全国锦标赛冠军，不愧为高手中的高手。",
		bestRankInfo = "第四届全国锦标赛冠军",
		icon = "img/lordsinglexhcg/jjmatch/player_%d_icon.png"
	},
	{
		playerId = 8,
		playerName = "飞鸟与鱼的爱情",
		playerInfo = "连续两年打入个人全国锦标赛决赛1次夺冠，1次季军，实力超强。",
		bestRankInfo = "第五届全国锦标赛冠军",
		icon = "img/lordsinglexhcg/jjmatch/player_%d_icon.png"
	},
	{
		playerId = 9,
		playerName = "◥◣桑神◢◤",
		playerInfo = "叫牌率极高喜欢单打独斗当地主，做农民时又有各种精彩的配合，高手实至名归。",
		bestRankInfo = "第六届全国锦标赛冠军",
		icon = "img/lordsinglexhcg/jjmatch/player_%d_icon.png"
	},
	{
		playerId = 10,
		playerName = "秦主任的哥",
		playerInfo = "打法灵活多变，擅长和搭档配合，打的一手好牌让同伴赞不绝口。",
		bestRankInfo = "第六届全国锦标赛亚军",
		icon = "img/lordsinglexhcg/jjmatch/player_%d_icon.png"
	},
	{
		playerId = 11,
		playerName = "哲姑",
		playerInfo = "JJ斗地主的知名高手，各种比赛出镜率极高，获得大小冠军无数。",
		bestRankInfo = "第四届全国锦标赛季军",
		icon = "img/lordsinglexhcg/jjmatch/player_%d_icon.png"
	},
	{
		playerId = 12,
		playerName = "牌王",
		playerInfo = "线上线下比赛胜率99％，记牌指数★★★★★，搭档配合指数★★★★★，运气指数★。",
		bestRankInfo = "神秘人物",
		icon = "img/lordsinglexhcg/jjmatch/player_%d_icon.png"
	},
	{
		playerId = 13,
		playerName = "寂寞风沉默雨",
		playerInfo = "JJ斗地主解说专家，电视台斗地主金牌解说，记牌指数★★★★，搭档配合指数★★★★，运气指数★★★★。",
		bestRankInfo = "民间高手",
		icon = "img/lordsinglexhcg/jjmatch/player_%d_icon.png"
	},
}

return SingleGameConfig



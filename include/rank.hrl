-define(UNION_TYPE_FIX, 	0).			%% 固定节点开
-define(SERVER_ID, 	110).				%% 服务器id
-define(ONE_DAY_SECONDS,        86400).        %%一天的时间（秒） 
-define(WARNING_MSG(Format, Args),
    logger:warning_msg(?MODULE,?LINE,Format, Args)).


-define(DIC_RANK, 			dic_rank). 				%% 所有上榜者
-define(DIC_RANK_SHOW, 		dic_rank_show).			%% 策划要求有排名的上榜者
-define(NEED_SHOW_LEN,    			300).					%% 需要排名的人数
-define(DIRTY_STATE_OLD,     		0).    					%% 数据无需更新（旧数据)
-define(DIRTY_STATE_UPDATE,  		1).    					%% 数据需要更新
-define(AI_SIGN,                 	1).						%% 1表示是ai
-define(CACL_AI_ID(Val),            100000000 + Val).		%% 用9位数表示排行ai的id
-define(RAND_FALSE_RANK,            [{1,30,10001,20000},{31,60,5001,10000},{61,90,3001,5000},{91,120,1001,3000},{121,150,301,1000}]).
-define(RANK_AI_INIT_GATE, [{1, 50}]).
-define(RANK_AI_NUM, 50).


-define(SAVE_TICK,  2 * 60 * 60). %% 2小时保存一次

-define(LOOP_TICK,  				1 * 1000).
-define(ADD_AI_TICK,  				60). 		%% 创建ai的时间间隔
-define(ADD_GATE_TIME,              13500).		%% 凌晨到3:45的秒数




-record(ets_users_rank, {	
      user_id = 0,                            %% 用户id	
      nick_name = "",                         %% 昵称	
      rank = 0,                               %% 排名	
      rank_time = 0,                          %% 上榜的时间	
      val = 0,                                %% 排名的值	
      is_ai = 0,                              %% 0不是机器人,1是	
      other_data = 0                          %% 其它	
    }).	
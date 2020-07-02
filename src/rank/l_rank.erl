%% @author chenkailun
%% @doc @todo Add description to l_rank.
%% 排行榜

-module(l_rank).
-include("rank.hrl").

%% ====================================================================
%% API functions
%% ====================================================================
-export([
		 clear_rank_info/0,
		 init_rank/0,
		 get_rank_info/2,
		 add_rank_info/4,
		 get_end_time/1,
		 mod_save/0,
		 add_ai_info/3,
		 add_ai_gate/2,
		 change_nick/2,
		 get_rand_name/0
		 ]).

%% 结算清除排行榜信息
clear_rank_info() ->
	db_rank:delete_rank_info(),
	put(?DIC_RANK, {0, []}), 
	put(?DIC_RANK_SHOW, []).


%% 初始化排行榜
init_rank() ->
	case db_rank:get_rank() of
		[] ->
			put(?DIC_RANK, {0, []}),
			put(?DIC_RANK_SHOW, []),
			AiNum = 0;
		DBS ->
			{RankL, AiNum} = init_rank(DBS, [], 0),
			{SortRank, CoditionVal} = sort_set_rank(RankL, ?NEED_SHOW_LEN, 0),
			ShowList = lists:sublist(SortRank, ?NEED_SHOW_LEN),
			put(?DIC_RANK_SHOW, ShowList),
			put(?DIC_RANK, {CoditionVal, SortRank})
	end,
	NeedAiNum = l_define:get_define(?RANK_AI_NUM, 50),
	case AiNum of
		0 ->
			NeedAiNum;
		_ ->
			max(0, NeedAiNum - AiNum)
	end.
			

%% 获取排行榜信息
get_rank_info(UserID,  Nick) ->
	ShowList = l_tool:get_dic(?DIC_RANK_SHOW),
	case lists:keyfind(UserID, #ets_users_rank.user_id, ShowList) of
		false -> 
			{ConditionVal, RankL} = l_tool:get_dic(?DIC_RANK),
			Now = m_timer:now_seconds(),
			case lists:keyfind(UserID, #ets_users_rank.user_id, RankL) of
				false ->
					_Rank = #ets_users_rank{
										   nick_name = Nick,
										   rank = 0,
										   val = 0
										  };
				RankOld when Now > RankOld#ets_users_rank.rank_time + 60 
				  orelse RankOld#ets_users_rank.rank == 0 ->
					FalseRank = get_false_rank(RankOld#ets_users_rank.val),
					Rank = RankOld#ets_users_rank{rank = FalseRank, 
												  rank_time = Now,
												  other_data = ?DIRTY_STATE_UPDATE},
					NRankL = lists:keyreplace(UserID, #ets_users_rank.user_id, RankL, Rank),
					put(?DIC_RANK, {ConditionVal, NRankL});
				RankOld ->
					_Rank = RankOld
			end;
		_Rank ->
			ok
	end,
	LastShowList = lists:sublist(ShowList, 50),
	LastShowList.

%% 判断是否需要加入排行榜
add_rank_info(UserID, Nick, Val, Now) ->
	add_rank_info(UserID, Nick, Val, Now, 0).

%% IsAI 1= 机器人,  0=玩家
add_rank_info(UserID, Nick, Val, Now, IsAI) ->
	{ConditionVal, RankL} = l_tool:get_dic(?DIC_RANK, {0, []}),
	case get_new_rank_list(UserID, Nick,Val, RankL, Now, IsAI) of
		{error, no_change} ->
			{error, no_change};
		{Rank, NRankL} ->
			if Val > ConditionVal ->
				   ShowL = l_tool:get_dic(?DIC_RANK_SHOW),
				   {NShowL, NConditionVal} = change_show_rank(Rank, ShowL),
				   put(?DIC_RANK_SHOW, NShowL),
		   		   put(?DIC_RANK, {NConditionVal, NRankL});
			   true ->
					put(?DIC_RANK, {ConditionVal, NRankL})
			end
	end.


%% 获取排行榜结算时间
get_end_time(Now) ->
	other_fun:get_current_weakday_zero(Now, 7) + ?ONE_DAY_SECONDS - 1.


%% 定时保存排行榜信息
mod_save() ->
	{ConditionVal, List} = l_tool:get_dic(?DIC_RANK),
	{NewList, DbList} = mod_save_detail(List, [], []),
	put(?DIC_RANK, {ConditionVal, NewList}),
	case DbList of
		[] ->
			skip;
		_ ->
			db_rank:update_users_rank(DbList)
	end.

%% 改名同步
change_nick(UserID, Nick) ->
	ShowList = l_tool:get_dic(?DIC_RANK_SHOW),
	case lists:keyfind(UserID, #ets_users_rank.user_id, ShowList) of
		false -> 
			skip;
		ShowRank ->
			NShowRank = ShowRank#ets_users_rank{nick_name = Nick, other_data = ?DIRTY_STATE_UPDATE},
			NShowList = lists:keyreplace(UserID, #ets_users_rank.user_id, ShowList, NShowRank),
			put(?DIC_RANK_SHOW, NShowList)
	end,
	{ConditionVal, RankL} = l_tool:get_dic(?DIC_RANK),
	case lists:keyfind(UserID, #ets_users_rank.user_id, RankL) of
		false ->
			skip;
		RankOld ->
			Rank = RankOld#ets_users_rank{nick_name = Nick, other_data = ?DIRTY_STATE_UPDATE},
			NRankL = lists:keyreplace(UserID, #ets_users_rank.user_id, RankL, Rank),
			put(?DIC_RANK, {ConditionVal, NRankL})
	end.

%% 生成ai
%% 防止ai同时生成 所以用Now - Num 表示生成时间
add_ai_info(Num, Now, AiIdSign) when 0 < Num -> 
	[{GateMin, GateMax}]= l_define:get_define(?RANK_AI_INIT_GATE, [{1, 50}]),
	Nick = get_rand_name(),
	AiID = ?CACL_AI_ID(AiIdSign),
	add_rank_info(AiID, Nick, l_tool:rand(GateMin, GateMax), Now - Num, ?AI_SIGN),
	add_ai_info(Num - 1, Now, AiIdSign - 1);

add_ai_info(_, _Now, _AiIdSign) ->
	ok.

%% 定时给ai添加关卡数
add_ai_gate(AddGateMin, AddGateMax) ->
	{_, RankL} = l_tool:get_dic(?DIC_RANK),
	NRankL = add_ai_gate_detail(RankL, AddGateMin, AddGateMax, []),
	{SortRank, CoditionVal} = sort_set_rank(NRankL, ?NEED_SHOW_LEN, 0),
	ShowList = lists:sublist(SortRank, ?NEED_SHOW_LEN),
	put(?DIC_RANK_SHOW, ShowList),
	put(?DIC_RANK, {CoditionVal, SortRank}).

%% ====================================================================
%% Internal functions
%% ====================================================================
init_rank([], RankL, AiNum) ->
	{RankL, AiNum};
init_rank([Rank|T], RankL, AiNum) ->
	NH = list_to_tuple([ets_users_rank | Rank]),
	case NH#ets_users_rank.is_ai of
		?AI_SIGN ->
			init_rank(T, [NH|RankL], AiNum + 1);
		_ ->
			init_rank(T, [NH|RankL], AiNum)
	end.


%% 玩家有记录更新
get_new_rank_list(UserID, Nick, Val, List, Now, IsAi) ->
	case lists:keyfind(UserID, #ets_users_rank.user_id, List) of
		false ->
			Rank = #ets_users_rank{
								   user_id = UserID,
								   nick_name = Nick,
								   rank = get_false_rank(Val),
								   rank_time = Now,
								   val= Val,
								   is_ai = IsAi,
								   other_data = ?DIRTY_STATE_UPDATE},
			{Rank, [Rank|List]};
		Rank when Val > Rank#ets_users_rank.val ->
			NRank = Rank#ets_users_rank{
										nick_name = Nick,
										rank = get_false_rank(Val),
										rank_time = Now,
										val= Val,
										other_data = ?DIRTY_STATE_UPDATE},
			DelList = lists:keydelete(UserID, #ets_users_rank.user_id, List),
			{NRank, [NRank|DelList]};
		_ ->
			{error, no_change}
	end.

%% 改变展示榜
change_show_rank(Rank, ShowL) ->
	case lists:keyfind(Rank#ets_users_rank.user_id, #ets_users_rank.user_id, ShowL) of
		false ->
			{SortRank, CoditionVal} = sort_set_rank([Rank|ShowL], ?NEED_SHOW_LEN, 0),
			NShowL = lists:sublist(SortRank, ?NEED_SHOW_LEN),
			{NShowL, CoditionVal};
		_OldRank ->
			DelShowL = lists:keydelete(Rank#ets_users_rank.user_id, #ets_users_rank.user_id, ShowL),
			sort_set_rank([Rank|DelShowL], ?NEED_SHOW_LEN, 0)
	end.
	

%% 排名
sort_set_rank(L, NeedLen, Val) ->
	{L1, _, _, NVal} = lists:foldl(fun set_fun/2, {[], 1, NeedLen, Val}, lists:sort(fun sort_set_fun/2, L)), 
	L2 = lists:reverse(L1),
	{L2, NVal}.

set_fun(Info, {Rel, Rank, NeedLen, Val}) ->
	case Rank of
		NeedLen ->
			NVal = Info#ets_users_rank.val;
		_ ->
			NVal = Val
	end,
	NewInfo = Info#ets_users_rank{rank = Rank},
	{[NewInfo|Rel], Rank + 1, NeedLen, NVal}.
	

sort_set_fun(V1, V2) ->
	if V1#ets_users_rank.val > V2#ets_users_rank.val ->
		   true;
	   V1#ets_users_rank.val < V2#ets_users_rank.val ->
		   false;
	   V1#ets_users_rank.rank_time =< V2#ets_users_rank.rank_time ->
		   true;
	   true ->
		   false
	end.


%% 定时保存排行榜信息
mod_save_detail([], List, DbList) ->
	{List, DbList};
mod_save_detail([H | Tail], List, DbList) ->
	case H#ets_users_rank.other_data of
		?DIRTY_STATE_UPDATE ->
			NewH = H#ets_users_rank{other_data = ?DIRTY_STATE_OLD},
			mod_save_detail(Tail, [NewH | List], [NewH | DbList]);
		_ ->
			mod_save_detail(Tail, [H | List], DbList)
	end.

%% 定时给ai添加关卡数
add_ai_gate_detail([], _AddGateMin, _AddGateMax, L) ->
	L;
add_ai_gate_detail([H|T], AddGateMin, AddGateMax, L) ->
	case H#ets_users_rank.is_ai of
		?AI_SIGN ->
			NVal = H#ets_users_rank.val + l_tool:rand(AddGateMin, AddGateMax),
			NH = H#ets_users_rank{val = NVal, other_data = ?DIRTY_STATE_UPDATE},
			add_ai_gate_detail(T, AddGateMin, AddGateMax, [NH|L]);
		_ ->
			add_ai_gate_detail(T, AddGateMin, AddGateMax, [H|L])
	end.


%% ai随机名
get_rand_name() ->
	FirstNameL = [],
	NameL = [],
	[{FirstName}] = lists:nth(l_tool:rand(1, length(FirstNameL)), FirstNameL),
	[{Name}] = lists:nth(l_tool:rand(1, length(NameL)), NameL),
	<<FirstName/binary, Name/binary>>.


%% 大于300的排名规则
get_false_rank(Gate) ->
	get_false_rank_detail(?RAND_FALSE_RANK, Gate).

get_false_rank_detail([], _Gate) ->
	10000;
get_false_rank_detail([{Min, Max, MinVal, MaxVal}|T], Gate) ->
	if Gate >= Min, Gate =< Max ->
		   l_tool:rand(MinVal, MaxVal);
	   true ->
		   get_false_rank_detail(T, Gate)
	end. 
	
	
	
%% @author Administrator
%% @doc @todo Add description to m_rank.


-module(m_rank).
-behaviour(gen_server).
-include("rank.hrl").
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% ====================================================================
%% API functions
%% ====================================================================
-export([
		 get_pid/1,
		 start_link/2
		]).


%% ====================================================================
%% Behavioural functions
%% ====================================================================
-define(PROCESS_NAME_SIGN, m_rank_process).


start_link(ProcessName, Arg) ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [ProcessName, Arg], []).
%% init/1
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:init-1">gen_server:init/1</a>
-spec init(Args :: term()) -> Result when
	Result :: {ok, State}
			| {ok, State, Timeout}
			| {ok, State, hibernate}
			| {stop, Reason :: term()}
			| ignore,
	State :: term(),
	Timeout :: non_neg_integer() | infinity.
%% ====================================================================
init([ProcessName, RankType]) ->
    try
        do_init([ProcessName, RankType])
    catch
        _:Reason ->
            ?WARNING_MSG("m_rank init is exception:~w",[Reason]),
            ?WARNING_MSG("get_stacktrace:~p",[erlang:get_stacktrace()]),
            {stop, normal}
    end.

do_init([ProcessName, RankType]) ->
    process_flag(trap_exit, true),
    l_process:register(global, ProcessName, self()),
    l_process:write_monitor_pid(self(), ?MODULE, {}),
	Now = other_fun:now_seconds(),
	AiNum = l_rank:init_rank(RankType),
	EndTime = l_rank:get_end_time(Now),
    erlang:send_after(?LOOP_TICK, self(), {'loop'}),
	StateMap = #{end_time => EndTime, last_time => Now,  save_time => Now + ?SAVE_TICK, need_ai => AiNum},
    {ok, StateMap}.

get_pid(RankType) ->
	ProcessSign = other_fun:process_name_without_server(?PROCESS_NAME_SIGN, [RankType]),
	other_fun:init_war_pid(ProcessSign, ?MODULE, 0, 0, [RankType], ?UNION_TYPE_FIX).
%% handle_call/3
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:handle_call-3">gen_server:handle_call/3</a>
-spec handle_call(Request :: term(), From :: {pid(), Tag :: term()}, State :: term()) -> Result when
	Result :: {reply, Reply, NewState}
			| {reply, Reply, NewState, Timeout}
			| {reply, Reply, NewState, hibernate}
			| {noreply, NewState}
			| {noreply, NewState, Timeout}
			| {noreply, NewState, hibernate}
			| {stop, Reason, Reply, NewState}
			| {stop, Reason, NewState},
	Reply :: term(),
	NewState :: term(),
	Timeout :: non_neg_integer() | infinity,
	Reason :: term().
%% ====================================================================
handle_call(Request, From, State) ->
    try
        do_call(Request, From, State) 
    catch
        _:Reason ->
            ?WARNING_MSG("m_rank handle_call is exception:~w,Info:~w",[Reason, Request]),
            ?WARNING_MSG("get_stacktrace:~p", [erlang:get_stacktrace()]),
            {reply, ok, State}
    end.



%% handle_cast/2
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:handle_cast-2">gen_server:handle_cast/2</a>
-spec handle_cast(Request :: term(), State :: term()) -> Result when
	Result :: {noreply, NewState}
			| {noreply, NewState, Timeout}
			| {noreply, NewState, hibernate}
			| {stop, Reason :: term(), NewState},
	NewState :: term(),
	Timeout :: non_neg_integer() | infinity.
%% ====================================================================
handle_cast(Info, State) ->
    try
        do_cast(Info, State)
    catch
        _:Reason ->
            ?WARNING_MSG("m_rank handle_cast is exception:~w,Info:~w",[Reason, Info]),
            ?WARNING_MSG("get_stacktrace:~p", [erlang:get_stacktrace()]),
            {noreply, State}
    end.


%% handle_info/2
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:handle_info-2">gen_server:handle_info/2</a>
-spec handle_info(Info :: timeout | term(), State :: term()) -> Result when
	Result :: {noreply, NewState}
			| {noreply, NewState, Timeout}
			| {noreply, NewState, hibernate}
			| {stop, Reason :: term(), NewState},
	NewState :: term(),
	Timeout :: non_neg_integer() | infinity.
%% ====================================================================
handle_info(Info, State) ->
    try
        do_info(Info, State)
    catch
        _:Reason ->
            ?WARNING_MSG("m_rank handle_cast exception:~w~n,Info:~w", [Reason, Info]),
            ?WARNING_MSG("get_stacktrace:~p", [erlang:get_stacktrace()]),
            {noreply, State}
    end.


%% terminate/2
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:terminate-2">gen_server:terminate/2</a>
-spec terminate(Reason, State :: term()) -> Any :: term() when
	Reason :: normal
			| shutdown
			| {shutdown, term()}
			| term().
%% ====================================================================
terminate(Reason, State) ->
    ok.


%% code_change/3
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:code_change-3">gen_server:code_change/3</a>
-spec code_change(OldVsn, State :: term(), Extra :: term()) -> Result when
	Result :: {ok, NewState :: term()} | {error, Reason :: term()},
	OldVsn :: Vsn | {down, Vsn},
	Vsn :: term().
%% ====================================================================
code_change(OldVsn, State, Extra) ->
    {ok, State}.


%% ====================================================================
%% Internal functions
%% ====================================================================
%%---------------------do_call--------------------------------
%% 该函数只限调试使用，程序请勿调用
do_call({apply_call, Module, Method, Args}, _From, State) ->
    Reply  = 
    case apply(Module, Method, Args) of
         {'EXIT', Info} ->  
             ?WARNING_MSG("~w_call error: Module=~p, Method=~p, Reason=~p", 
                          [?MODULE, Module, Method, Info]),
             {false, error};
         DataRet -> DataRet
    end,
    {reply, Reply, State};

do_call(Info, _From, State) ->
    ?WARNING_MSG("m_rank call is not match:~w",[Info]),
    {reply, ok, State}.

%% ---------------------do_cast-------------------------------
%% 统一模块+过程调用(cast)
do_cast({apply_cast, Module, Method, Args}, State) ->
    case apply(Module, Method, Args) of
         {'EXIT', Info} ->  
             ?WARNING_MSG("~w_cast error: Module=~p, Method=~p, Args =~p, Reason=~p",
                          [?MODULE, Module, Method, Args, Info]),
             error;
         _ -> 
			 ok
    end,
    {noreply, State};


do_cast(Info, State) ->
    ?WARNING_MSG("m_rank cast is not match:~w",[Info]),
    {noreply, State}.


%% ---------------------do_info-------------------------------
do_info({'loop'}, State) ->
    erlang:send_after(?LOOP_TICK, self(), {'loop'}),
    Now = m_timer:now_seconds(),
	ToDayTime = other_fun:get_today_current_second_no(Now),
	OldToDayTime = other_fun:get_today_current_second_no(maps:get(last_time, State)),
	Week = other_fun:get_dayofweek_no(Now),
	MSaveTime = maps:get(save_time, State),
	if Now >  MSaveTime ->
		   SaveTime = Now + ?SAVE_TICK,
		   l_rank:mod_save(),
		   State1 = maps:update(save_time, SaveTime, State);
	   true ->
		   State1 = State
	end,
	
	case other_fun:is_same_week(maps:get(end_time, State), Now) of
		true ->
			State2 = State1;
		_ ->
			l_rank:clear_rank_info(),
			EndTime = l_rank:get_end_time(Now),
			State2 = State1#{end_time := EndTime, need_ai := ?RANK_AI_NUM}
	end,
	MNeedAi = maps:get(need_ai, State2),
	MAiTime = maps:get(ai_time, State2),
	case Week of
		1 when MNeedAi > 0 andalso Now > MAiTime ->
			if ToDayTime > 60 ->
				   [{AiMin, AiMax}] = [{5, 10}],
				   RandAiNum = min(l_tool:rand(AiMin, AiMax), maps:get(need_ai, State2)),
				   NeedAi = MNeedAi - RandAiNum,
				   l_rank:add_ai_info(RandAiNum, Now, maps:get(need_ai, State2));
				true ->
					NeedAi = MNeedAi
			end,
			State3 = State2#{ai_time := Now + ?ADD_AI_TICK, need_ai := NeedAi};
		_ ->
			State3 = State2
	end,
	
	AddGateTime = ?ADD_GATE_TIME,
	if ToDayTime >= AddGateTime andalso OldToDayTime < AddGateTime ->
		   TempAddGateL = [],
		   case lists:keyfind(Week, 1, TempAddGateL) of
			   {Week, AddGateMin, AddGateMax} ->
				   l_rank:add_ai_gate(AddGateMin, AddGateMax);
			   _ ->
				   skip
		   end;
	   true ->
		   skip
	end,
    {noreply, State3#{last_time := Now}};

do_info(Info, State) ->
    ?WARNING_MSG("m_rank info is not match:~w",[Info]),
    {noreply, State}.



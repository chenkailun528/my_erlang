%% @author Administrator
%% @doc @todo Add description to other_fun.


-module(other_fun).
-include("rank.hrl").
%% ====================================================================
%% API functions
%% ====================================================================
-export([
		 init_war_pid/3,
		 is_process_alive/1,
		 seconds_to_localtime/1,
		 get_current_weakday_zero/2,
		 now_seconds/0
		]). 

init_war_pid(ProcessNameSign, Module, ExtendArg) ->
	ProcessName = process_name_without_server(ProcessNameSign, ?SERVER_ID),
	get_union_pid_local(ProcessName, Module, ExtendArg).

%% ====================================================================
%% Internal functions
%% ====================================================================
process_name_without_server(Prefix, List) ->
	tool:to_atom(lists:concat(lists:flatten([Prefix] ++ lists:map(fun(T) -> ['_', tool:to_integer(T)] end, List)))).

get_union_pid_local(ProcessName, Module, Extend) ->
	case process_util:get_process_pid({global, ProcessName}) of
		Pid when is_pid(Pid) ->
			case other_fun:is_process_alive(Pid) of
				true -> 
					Pid;
				false ->
					start_process_detail(ProcessName, Module, Extend)
			end;
		_ ->
			start_process_detail(ProcessName, Module, Extend)
	end.

start_process_detail(ProcessName, Module, Extend) ->
	case supervisor:start_child(server_sup, 
								{
								 {Module, ProcessName}, 
								 {?MODULE, start_link, [[Module, ProcessName, Extend]]},	 
								 permanent, 10000, supervisor, [Module]}
							   ) of
		{ok, Pid} ->	
			Pid;
		{error, {already_started,Pid}} ->	
			?WARNING_MSG("already_started: ~p, Module: ~p, ProcessName : ~p~n", [Pid, Module, ProcessName]),
			global:re_register_name(ProcessName, Pid),
			Pid;				
		_Error ->
			?WARNING_MSG("start_process_detail:~w~n", [_Error]),
			?WARNING_MSG("get_stacktrace:~p",[erlang:get_stacktrace()]),
			undefined
	end.


is_process_alive(Pid) ->    
	try 
		if is_pid(Pid) ->
     			case rpc:call(node(Pid), erlang, is_process_alive, [Pid], 5000) of
					{badrpc, _Reason}  -> false;
					Res -> Res
				end;
			true -> false
		end
	catch 
		_:_ -> false
	end.



%% 日期
seconds_to_localtime(Seconds) ->
    DateTime = calendar:gregorian_seconds_to_datetime(Seconds + 62167219200),
    calendar:universal_time_to_local_time(DateTime).


%% 返回传入时间戳的当前周的周几零点
%% 如传入Now, 7 则返回当前的周日零点时间戳
get_current_weakday_zero(Seconds, WeakDay) ->	
	{{Year, Month, Day}, Time} = seconds_to_localtime(Seconds),
    DayOfWeek = calendar:day_of_the_week(Year, Month, Day),
    PastSec = calendar:time_to_seconds(Time),
    TureWeakDay = 													% 过滤不合法WeakDay
    	case WeakDay rem 7 of
    		0 ->
    			7;
    		TureDay ->
    			TureDay
    	end,
    Seconds + (TureWeakDay - DayOfWeek) * ?ONE_DAY_SECONDS - PastSec.


now_seconds()->
	[{timer, {Now, _}}] = ets:lookup(ets_timer, timer),
	{MegaSecs, Secs, _MicroSecs} = Now,	
	MegaSecs * 1000000 + Secs.
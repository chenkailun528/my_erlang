%% @author Administrator
%% @doc @todo Add description to other_to_fun.
%% table 转取字段，针对结构比较长的内容做自动生成，减少代码长度

-module(auto_code).

%%--------------------------------------------------------------------
%% Include files 
%%--------------------------------------------------------------------
-define(HRL_CONVERT_DATA_DIR,		"../include/").
-define(HRL_READ_DATA_DIR,		"../include/record.hrl").


-define(Data_other_user, [proto_type,
						  is_show_list,
						  infant_state,
						  pid_send,
						  duplicate_id,
						  club_id,
						  club_name,
						  m_id,
						  total_level]).

-define(Data_other_task, [is_new_finish,
						  is_new,
						  dirty_state,
						  condition,
						  cross_robbery]).


-define(HRL_CONVERT_DATA, 
		[{"h_player.hrl", "h_player", 'P',
		  [{?Data_other_user, 
			user_other,
			["#ets_users.other_data"],
			"OtherData = H#ets_users.other_data#user_other{", 
			"H#ets_users{other_data = OtherData}"}]},
		 {"h_task.hrl", "h_task", 'T',
		  [{?Data_other_task, 
			other_task,
			["#ets_users_tasks.other_data"],
			"OtherData = H#ets_users_tasks.other_data#other_task{", 
			"H#ets_users_tasks{other_data = OtherData}"}]}
		]).





%%--------------------------------------------------------------------
%% External exports
%%--------------------------------------------------------------------
-compile(export_all). 

%%====================================================================
%% External functions 
%%====================================================================

start_game_get_data() ->
	start(?HRL_CONVERT_DATA_DIR, ?HRL_CONVERT_DATA, table_to_get_data).



%% ====================================================================
%% Internal functions
%% ====================================================================
start(FileName, Tables, Func)->	
	try
		Res = other_to_fun:Func(FileName, Tables),
		io:format("====~w~n", [finish]),
		io:format("Res:~w~n",[Res])
%% 	 	erlang:halt()
	catch
		_E : Reason ->
			io:format("Reason:~w~n",[Reason]),
			error
	end.

%%	table 转取字段，针对结构比较长的内容做自动生成，减少代码长度
table_to_get_data(_FileDir, []) ->
	io:format("db convert get data finished!~n"),	
	ok;
table_to_get_data(FileDir, [{TmpFileName, ModuleName, Logo, Tables}|T]) ->
	FileName = FileDir ++ TmpFileName,
	Head1 = io_lib:format("%%% Created : ~s \t\n%%% Description: db to data, Do not manually modify \t\n-ifndef('~s').\t\n-define('~s', true).\t\n",
										  [time_format(), string:to_upper(ModuleName), string:to_upper(ModuleName)]),
	file:delete(FileName),
	file:write_file(FileName, Head1, [append]),	
	io:format("~n~n"),
	F1 = fun(Table, [TmpContent]) ->
				 case Table of 
					 {Record_list, Record_name, Data_name, SetHead, SetTail} ->
						 A = list_to_get_data1(Record_list, Record_name, Data_name, SetHead, SetTail, Logo);
					 _-> 
						 A = [""]
				 end,
				 [A | TmpContent]
		 end,
	
	Mid = lists:foldr(F1, [""], Tables),
	file:write_file(FileName, Mid, [append]),
	
	End = "-endif.\t\n% DB_CONVERT_GET_DATA	\t\n",
	file:write_file(FileName, End, [append]),
	table_to_get_data(FileDir, T).


list_to_get_data1(Fields, RecordName, DataName, SetHead, SetTail, Logo) ->
	UpdateInfoHead = io_lib:format("\t\n%% ~s \t\n", [RecordName]),
	UpdateInfo0 = field_to_get_data(Fields, RecordName, DataName, SetHead, SetTail, Logo, [], []),
	UpdateInfo = lists:reverse(UpdateInfo0),
	UpdateInfoEnd = " \t\n",
	
	io:format(" ~s ~n~n", [RecordName]),
	[UpdateInfoHead ++ UpdateInfo ++ UpdateInfoEnd].


field_to_get_data([], _RecordName, _DataName, _SetHead, _SetTail, _Logo, _NotCreateList, List) ->
	List;
field_to_get_data([[Name]|T], RecordName, DataName, SetHead, SetTail, Logo, NotCreateList, List) ->
	List1 = field_to_get_data1(Name, NotCreateList, DataName, RecordName, SetHead, SetTail, List, Logo),
	field_to_get_data(T, RecordName, DataName, SetHead, SetTail, Logo, NotCreateList, List1);
field_to_get_data([Name|T], RecordName, DataName, SetHead, SetTail, Logo, NotCreateList, List) ->
	List1 = field_to_get_data1(Name, NotCreateList, DataName, RecordName, SetHead, SetTail, List, Logo),
	field_to_get_data(T, RecordName, DataName, SetHead, SetTail, Logo, NotCreateList, List1).

field_to_get_data1(Name, NotCreateList, DataName, RecordName, SetHead, SetTail, List, Logo) ->
	case lists:member(Name, NotCreateList) of
		true ->
			FieldContent = "";
		_ ->
			FieldContent1 = io_lib:format("%%~s#~s.~s\t\n-define(GET_~s_~s(H),		H~s#~s.~s). \t\n",
										  [DataName, RecordName, Name, Logo, Name, DataName, RecordName, Name]),
			FieldContent2 = io_lib:format("-define(SET_~s_~s(H, Value),\t\n	begin \t\n		~s~s=Value},\t\n		~s \t\n	end). \t\n\t\n", 
										  [Logo, Name, SetHead, Name, SetTail]),
			FieldContent = FieldContent1 ++ FieldContent2
	end,
	[FieldContent|List].



%% time format
one_to_two(One) -> 
	io_lib:format("~2..0B", [One]).
time_format() -> 
	{Y,M,D} = erlang:date(),
	
	{H,MM,S} = erlang:time(),
	
	lists:concat([Y, "_", one_to_two(M), "_", one_to_two(D), "_", 
				  one_to_two(H) , "_", one_to_two(MM), "_", one_to_two(S)]).



get_test() ->
	try
		FileName = ?HRL_READ_DATA_DIR,
		file:delete(FileName),
		{ok, File} = file:open(FileName, [read]),
		io:format("---------~p~n",[File]),
		io:format("====~w~n", [finish])
	%% 	 	erlang:halt()
	catch
		_E : Reason ->
			io:format("Reason:~w~n",[Reason]),
			error
	end.
	
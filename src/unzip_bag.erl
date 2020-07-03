%% @author Administrator
%% @doc @todo Add description to unzip_bag.


-module(unzip_bag).
-define(D_FILE, "E:\\unzip_bag").
-define(D_UN_FILE, "E:\\unzip_bag").


%% ====================================================================
%% API functions
%% ====================================================================
-export([start/0]).


start() ->
	case file:list_dir(?D_FILE) of
		{ok, Files} ->
			handle_file(Files),
			ok;
		_ ->
			error
	end.

handle_file([]) ->
	ok;
handle_file([H|T]) when length(H) > 3 ->
	CM = string:substr(H,length(H) - 3),
	ZipName = string:substr(H,1,length(H)-4),
	if CM == ".zip" ->
		   io:format("name is : ~s ~n", [lists:concat([?D_FILE, "\\", H])]),
		   zip:unzip(lists:concat([?D_FILE, "\\", H])),
		   EbinDirName = lists:concat([?D_FILE,"\\",ZipName,"\\","server","\\","ebin"]),
		   HrlDirName = lists:concat([?D_FILE,"\\",ZipName,"\\","server","\\","hrl"]),
		   DirName = lists:concat([?D_FILE,"\\",ZipName]),
		   case file:list_dir(DirName) of
			{ok, Files} ->
				read_sql_file(Files, DirName),
				ok;
			_ ->
				error
			end,
		   EbinLen =  calc_file_len(EbinDirName),
		   HrlLen = calc_file_len(HrlDirName),
		   io:format("ebin have nums:	~p~n",[EbinLen]),
		   io:format("hrl have nums:	~p~n",[HrlLen]),
		   ok;
	   true ->
		   error
	end,  
	handle_file(T);

handle_file([_H|T]) ->
	handle_file(T).


read_sql_file([], _DirName) ->
	ok;
read_sql_file([H|T], DirName) when length(H) > 12 ->
	CM = string:substr(H,length(H) - 12),
	if CM == "_template.sql" ->
		FileName = lists:concat([DirName,"\\",H]),
		case file:open(FileName,read) of
			{ok, F} ->
				io:format("~n---------------------------------------------template_sql_start~n"),
				print_line(F, 10000),		
				io:format("----------------------------------------------template_sql_end~n"),
				{ok, F1} = file:read_file(FileName),
				
				file:close(F),
				file:close(F1),
				ok;
			_R ->
				error
		end;
	 true ->
		   read_sql_file(T, DirName)
	end;  

read_sql_file([_H|T], DirName) ->
	read_sql_file(T, DirName).

print_line(_F, 0) ->
	ok;
print_line(F, Len) when Len > 9980->
	R = io:get_line(F, ''),
	R1 = string:substr(R,1,length(R)-1),
	case R1 of
		[] ->
			print_line(F, Len -1);
		_ ->
		 	io:format("~p~n",[R1]),
		 	case re:run("R1", "t_user*") of
		 		{match,_} ->
		 			io:format("error---------------find t_user*~n");
		 		_ ->
		 			skip
		 	end,
			print_line(F, Len -1)
	end;

print_line(F, Len)->
	R = io:get_line(F, ''),
	R1 = string:substr(R,1,length(R)-1),
	case R1 of
		[] ->
			print_line(F, Len -1);
		_ ->
			case re:run("R1", "t_user*") of
		 		{match,_} ->
		 			io:format("error---------------find t_user*~n");
		 		_ ->
		 			skip
		 	end,
			print_line(F, Len -1)
	end.




calc_file_len(DirName) ->	
	case file:list_dir(DirName) of
		{ok, Files} ->
			length(Files);
		_ ->
			0
	end.


	



%% ====================================================================
%% Internal functions
%% ====================================================================
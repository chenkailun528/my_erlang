%% @author Administrator
%% @doc @todo Add description to unzip_mp3.
%% 将相关的音乐缓存文件转换为mp3文件  网易音乐


-module(unzip_mp3).
-define(D_FILE, "E:\\mc").
-define(D_UN_FILE, "E:\\mc").
-define(D_FILE_MIE, 1024 * 1024 * 3).		%% 最小文件

-define(D_BXOR_64, (16#A3) + (16#A3 bsl 2) + (16#A3 bsl 4) + (16#A3 bsl 6)).

%% ====================================================================
%% API functions
%% ====================================================================
-export([start/0]).


start() ->
%% 	File = "H:\mc",
	case file:list_dir(?D_FILE) of
		{ok, Files} ->
			handle_file(Files),
			ok;
		_ ->
			error
	end.


handle_file([]) ->
	ok;
handle_file([H|T]) when length(H) > 2 ->
	CM = string:substr(H,length(H) - 2),
		
	if CM == ".uc" ->
		   io:format("name is : ~s ~n", [lists:concat([?D_FILE, "\\", H])]),
		   file_xor(H),
		   ok;
	   true ->
		   error
	end,
    
	handle_file(T);

handle_file([_H|T]) ->
	handle_file(T).



file_xor(Filename) ->
	case file:read_file(lists:concat([?D_FILE, "\\", Filename])) of
		{ok, Bin} when  byte_size(Bin) > (?D_FILE_MIE) ->
			Bin1 = bin_xor(Bin, <<>>),
			
			file:write_file(lists:concat([?D_UN_FILE, "\\", Filename, ".mp3"]), Bin1),
			ok;
		_ ->
			error
	end,
	ok.


bin_xor(<<>>, NewB) ->
	NewB;
bin_xor(Bin, NewB) when byte_size(Bin) < 2 ->
	<<NewB/binary, Bin/binary>>;
bin_xor(<<A:8, L/binary>>, NewB)->
	A1 = A bxor 16#A3,
	bin_xor(L, <<NewB/binary, A1:8>>).

	



%% ====================================================================
%% Internal functions
%% ====================================================================
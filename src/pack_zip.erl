%% @author Administrator
%% @doc @todo Add description to pack_zip.


-module(pack_zip).

%% TODO 打包完成后的路径
%% TODO 如果用户表有改动请把自己写的update_table.sql文件放到下面这个目录
-define(PACK_PATH, "E:\\pack_test").

%% TODO 打包项目路径  
-define(PROJECT_PATH, "F:\\Two\\xyx_server").  

%% TODO 有些项目用的头文件是放在include文件夹中，有些项目用的头文件是放在hrl文件夹中; 这里根据项目来
-define(HEAD_DIR_NAME, "hrl").    

%% TODO 需要打包的数据库相关配置
-define(DB_IP, "127.0.0.1").    	%% 数据库地址
-define(DB_NAME, "test").  		%% 数据库名字
-define(DB_PORT, "3306").  				%% 数据库端口
-define(DB_User_Name, "root").  		%% 数据库用户名
-define(DB_User_Pass, "110120").  %% 数据库密码

%% TODO 打包模板表用的名字 ，一般都是跟后台一起订的
-define(CREATE_ALL_TEMPLATE_NAME, "jt_create_template.sql"). 
-define(UPDATE_TABLE_NAME, "jt_update_table.sql"). 


%% TODO 这里可以写相关要运行的bat文件，比如编译 或改表版本号的文件。。。  太多了，不写了
-define(NEED_RUN_BAT_LIST, 
		[{"D:\\dashi\\","make_new.bat"}]). 

%% ====================================================================
%% API functions
%% ====================================================================
-export([
		 start/0
		]).

%% 开始打包
start() ->  
	%% 完全是出自于好看才sleep,没有任何作用
	timer:sleep(100),
	io:format("~npack all----------------------------:~p~n",[start]),
%% 	need_run_ahead_bat(?NEED_RUN_BAT_LIST),
	need_run_ahead_bat([]),
	{{Year, Month, Day},{_Hour, _Minute, _Second}} = calendar:local_time(), 
	LastYearTab = Year rem 1000,
	DateName = lists:concat([LastYearTab, change_new_val(Month), change_new_val(Day)]),
	MainPath = lists:concat([?PACK_PATH, "\\", DateName]), 
	DirPath = lists:concat([MainPath, "\\", "server"]), 
	EBinDirPath = lists:concat([DirPath, "\\", "ebin"]),
	HrlDirPath = lists:concat([DirPath, "\\", ?HEAD_DIR_NAME]),
	ProjectEbinPath = lists:concat([?PROJECT_PATH, "\\", "ebin"]), 
	ProjectHrlPath = lists:concat([?PROJECT_PATH, "\\", ?HEAD_DIR_NAME]), 
	loop_judge_dir_or_set([DirPath, EBinDirPath, HrlDirPath]),
	%% 判断有没有改变用户表的sql文件
	check_update_table(MainPath),
	loop_copy_dir([{ProjectEbinPath, EBinDirPath}, {ProjectHrlPath, HrlDirPath}]),
	%% 根据实际项目来确定是否生成模板表文件，有些项目是策划给的表
	pack_template_sql(MainPath),
	%% TODO 自动压缩成.zip 文件，前提是系统压缩工具的路径有添加到环境变量  win + r 输入winrar.exe 可知有否
	zip_fun(DateName),

	io:format("pack all----------------------------:~p~n",[success]),
	ok.


%% ====================================================================
%% Internal functions
%% ====================================================================
%% 循环创建对应的路径文件夹
loop_judge_dir_or_set([]) ->
	io:format("make dir : ~p~n~n",[success]),
	ok;

loop_judge_dir_or_set([Path|T]) ->
	judge_dir_or_set(Path),
	loop_judge_dir_or_set(T).

%% 循环拷贝对应的文件
loop_copy_dir([]) ->
	io:format("~ncopy_dir : ~p~n",[success]),
	ok;

loop_copy_dir([{FromDir, TarDir}|T]) ->
	copy_dir(FromDir, TarDir),
	io:format("copy_dir from : ~p~ncopy_dir target : ~p~n~n",[FromDir, TarDir]),
	loop_copy_dir(T).

%% 拷贝文件夹 FromDir要拷贝的文件夹路径 TarDir 拷贝到的目标文件夹
copy_dir(FromDir, TarDir)->
	%% 获取当前文件夹的所有文件列表(包括子文件夹)
	{ok, AllFile} = file:list_dir_all(FromDir),
	%% 尾递归遍历所有文件
	loop_copy(AllFile,FromDir,TarDir).

loop_copy(AllFile,FromDir,TarDir) ->
	case AllFile of
		[] ->
			ok;
		_ ->
			%% 每次拿第一个文件  One
			[One|Other]=AllFile,
			Path=FromDir++"/"++One,
			Tar=TarDir++"/"++One,
			%% 判断当前文件是否是文件夹
			case filelib:is_dir(Path) of
				true ->
					file:make_dir(Tar),
					copy_dir(Path,Tar);
				_ ->
					file:copy(Path, Tar)
			end,
			%%递归第一个文件后面的文件
			loop_copy(Other,FromDir,TarDir)
	end.

%% 判断目录是否存在并进行新建目录
judge_dir_or_set(Path) ->
	case filelib:is_dir(Path) of
		true ->
			ok;
		false ->
			set_dir_by_path(Path)
	end.

set_dir_by_path(Path) ->
	[Pan|PathList] = string:tokens(Path,"\\"),
	set_dir_by_path(PathList, Pan).


set_dir_by_path([],Dir) -> 
	Dir;    
set_dir_by_path([Path|PathList], Dir) ->
	DirList = lists:concat([Dir, "\\", Path]), 
	case filelib:is_dir(DirList) of
		true ->
			set_dir_by_path(PathList,DirList);
		false ->
			file:make_dir(DirList),
			set_dir_by_path(PathList,DirList)
	end.

%% 判断有没有改变用户表的sql文件
check_update_table(MainPath) ->
	UpdateSqlFrom = lists:concat([?PACK_PATH, "\\", ?UPDATE_TABLE_NAME]),
	UpdateSqlTarget = lists:concat([MainPath, "\\", ?UPDATE_TABLE_NAME]),
	case file:copy(UpdateSqlFrom, UpdateSqlTarget) of
		{ok, _} ->
			file:delete(UpdateSqlFrom),
			io:format("-------已成功将~s移动到~s目录------~n",[?UPDATE_TABLE_NAME, MainPath]),
			io:format("~n"),
			ok;
		_ ->
			io:format("！！！没有找到对应的更改用户表的sql文件，请确认这次更新没有改动到用户表！！！~n"),
			io:format("！！！没有找到对应的更改用户表的sql文件，请确认这次更新没有改动到用户表！！！~n"),
			io:format("！！！没有找到对应的更改用户表的sql文件，请确认这次更新没有改动到用户表！！！~n"),
			io:format("~n"),
			io:format("如果用户表有改动请把自己写的update_table.sql文件放到下面这个目录~s~n",[?PACK_PATH]),
			
			io:format("~n"),
			ok
	end.

%% 从数据库中打包模板表
pack_template_sql(MainPath) ->
	%% 获取出所有带template的表名存入临时文件
	TempPath = lists:concat([MainPath, "\\", "t_template.txt"]),
	ShowSqlStr = lists:concat(["mysql -u",?DB_User_Name," -p",?DB_User_Pass,
							   " -h",?DB_IP," -P",?DB_PORT," -D",?DB_NAME," -Bse",
							   "  \"show tables like '%%template%%'\" > ",TempPath]),
	os:cmd(ShowSqlStr),
	FilePath = lists:concat([MainPath, "\\", "t_template.txt"]),
	case file:open(FilePath, read) of
		{ok, F} ->
			TempNameStr = get_template_name_str(F, 0, " "),		
			file:close(F),
			create_template_sql(TempNameStr, MainPath),
			ok;
		_R ->
			io:format("error no create:  ~s~n", ["template.sql"])
	end,
	file:delete(TempPath),
	ok.


	

%% 防止死循环正常不会有10000张模板表
get_template_name_str(_F, Num, _Str) when Num > 10000 ->
	io:format("error---------- :~w~n",[Num]),
	error;

get_template_name_str(F, Num, Str)->
	R = io:get_line(F, ''),
	case R of
		eof ->
			io:format("have template num :~w~n",[Num]),
			Str;
		_ ->
			R1 = string:substr(R,1,length(R)-1),
			NStr = lists:concat([Str," ", R1]),
			get_template_name_str(F, Num + 1, NStr)
	end.

%% 创建sql模板文件
create_template_sql(TempNameStr, MainPath) ->
	SqlStr = lists:concat(["mysqldump -u",?DB_User_Name," -p",?DB_User_Pass,
							" -h",?DB_IP," -P",?DB_PORT,
						   " --default-character-set=utf8 ",?DB_NAME," ",
						   TempNameStr, " > ",MainPath, "\\", ?CREATE_ALL_TEMPLATE_NAME]),
 	os:cmd(SqlStr),
	ok.

%% 自动压缩成.zip 文件，前提是系统压缩工具的路径有添加到环境变量  win + r 输入winrar.exe 可知有否
zip_fun(DateName) ->
	ZipFileName = lists:concat([DateName , ".zip"]), 
	ZipCmd = lists:concat(["winrar.exe a -r ", ZipFileName, " ", DateName, "\\"]),
	do_cmd_bat(?PACK_PATH, ZipCmd),
	ok.

%% 月份/日小于10的时候是单数文件名不好看，强制转换为2位数
change_new_val(Val) ->
	if Val < 10 ->
		   lists:concat(["0", Val]);
	   true ->
		   Val
	end.



%% 需要提前运行的bat文件
need_run_ahead_bat([]) ->
	ok;
need_run_ahead_bat([{Path, Cmd}|T]) ->
	do_cmd_bat(Path, Cmd),
	need_run_ahead_bat(T).


do_cmd_bat(Path, Cmd) ->
	{ok, OldRrlPath} = file:get_cwd(),
	ErlPath = change_erl_path(string:tokens(Path,"\\"), ""),
	c:cd(ErlPath),
	os:cmd(Cmd),
	c:cd(OldRrlPath),
	ok.


%% 把路径改为erl读得懂的路径
change_erl_path([], ErlPath) ->
	ErlPath;
change_erl_path([H|T], ErlPath) when  ErlPath == ""->
	change_erl_path(T, lists:concat([ErlPath, H]));
change_erl_path([H|T], ErlPath) ->
	change_erl_path(T, lists:concat([ErlPath, "/", H])).
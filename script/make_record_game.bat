set ERLC=%BIN_PATH%erlc
set WERL=%BIN_PATH%werl

echo off

cd ../ebin


call %ERLC% -I ../include/ ../src/auto_code.erl

call %WERL% +P 1024000  -name ckl@127.0.0.1 -s auto_code start_game_get_data


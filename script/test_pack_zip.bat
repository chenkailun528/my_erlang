echo off

cd ../ebin

call erlc -I ../include/ ../src/pack_zip.erl

call werl +P 1024000  -name ckl@127.0.0.1 -s pack_zip start


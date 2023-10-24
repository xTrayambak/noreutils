#!/usr/bin/env sh

cd ../ &&
nimble build -d:release
./noreutils

hyperfine "./bin/base64 -d test_data/base64_001.txt" "base64 -d test_data/base64_001.txt" -N --warmup=10000

hyperfine "./bin/cat --number test_data/cat001.txt" "cat --number test_data/cat001.txt" -N --warmup=10000

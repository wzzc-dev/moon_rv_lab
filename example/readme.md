
# 简介

```shell
riscv64-unknown-elf-gcc -S -march=rv64gc -mabi=lp64d -O3 hello.c -o hello.s
riscv64-unknown-elf-gcc -march=rv64gc -mabi=lp64d hello.s -o a.out
cp ../_build/native/debug/build/cmd/main/main.exe rv-analyzer
./rv-analyzer disasm a.out >> output.txt
```
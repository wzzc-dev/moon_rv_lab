
# 简介

```shell
riscv64-unknown-elf-gcc -S -march=rv64gc -mabi=lp64d -O3 hello.c -o hello.s
riscv64-unknown-elf-gcc -march=rv64gc -mabi=lp64d hello.s -o a.out
cp ../_build/native/debug/build/cmd/main/main.exe rvkit
./rvkit disasm a.out >> output.txt
```

```shell
# 分析一个 RISC-V 固件
rvkit info firmware.bin        # 查看文件类型和结构
rvkit symbols firmware.bin     # 查看有哪些函数
rvkit cfg firmware.bin -n main -o main.dot  # 生成 main 函数的控制流图
rvkit disasm firmware.bin      # 反汇编查看实际指令
```
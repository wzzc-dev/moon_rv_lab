.data

.text
.global minimbt_main
minimbt_main:
  addi sp, sp, -24
  sd ra, 16(sp)
  sd s0, 8(sp)
  addi s0, sp, 24
block_1:
  li t2, 1
  addi sp, sp, -16
  sd t2, 0(sp)
  sd a1, 8(sp)
  mv a0, t2
  call minimbt_print_int
  ld a1, 8(sp)
  ld t2, 0(sp)
  addi sp, sp, 16
  ld ra, 16(sp)
  ld s0, 8(sp)
  addi sp, sp, 24
  ret

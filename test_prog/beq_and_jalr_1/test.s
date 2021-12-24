.L0:
lw s2, 0x20(s3) # 0x8000_0000
add s2, s4, s2  # 0x8000_0001
beq s2, s5, .L1 # if s2 == s5 then target
add s2, s2, s4  # 0x8000_0002
.L1:
sw s2, 0x1f(s2)  # 0x8000_0001
lw s6, 0x20(s3) # 0x8000_0001
jalr s7, s3, 4
add s2, s2, s4
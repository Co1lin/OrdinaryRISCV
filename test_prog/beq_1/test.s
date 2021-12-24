lw s2, 0x20(s3) # 0x8000_0001
add s2, s4, s2  # 0x8000_0002
beq s2, s5, .L1 # if s2 == s5 then target
add s2, s2, s4  # 0x8000_0003
.L1:
sw s2, 0x1e(s2)  # 0x8000_0002
lw s4, 0x20(s3) # 0x8000_0001
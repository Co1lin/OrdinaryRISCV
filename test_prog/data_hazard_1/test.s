lw s2, 0x20(s3) # 0x8000_0001
add s2, s4, s2  # 0x8000_0002
add s2, s2, s4  # 0x8000_0003
sw s2, 0x1d(s2)  # 0x8000_0003
add s2, s4, s2  # 0x8000_0004
add t0, t1, t2
add t3, t4, t5
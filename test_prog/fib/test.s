.section .text
.globl _start
_start:
    li s2, 1 # s2 =1 
    li s3, 0 # s3 = 0
    li s4, 101 # s4 = 101
    li s5, 1 # s5 = 1
_loop:
    beq s2, s4, _end # if s2 == s4 then end
    add s3, s3, s2; # s3 = s3 + s2
    add s2, s2, s5; # s2 = s2 + s5
    j _loop  # jump to loop
_end:
    li s6, 0x80000000 # s6 = 0x80100000
    sw s3, 0x100(s6) # 
    li s7, 0x10000000 # s7 = 0x10000000
    li s8, 100 # s8 = 'd'
_wait1: # wait until s9 != 0
    lb s10, 5(s7)
    andi s9, s10, 0b00100000
    beq s9, zero, _wait1 # if s9 == zero then _wait1
    sb s8, 0(s7) # save 'd'
    li s8, 111 # s8 = 'o'
_wait2: # wait until s9 != 0
    lb s10, 5(s7)
    andi s9, s10, 0b00100000
    beq s9, zero, _wait2 # if s9 == zero then _wait2
    sb s8, 0(s7) # save 'o'
    li s8, 110 # s8 = 'e'
_wait3: # wait until s9 != 0
    lb s10, 5(s7)
    andi s9, s10, 0b00100000
    beq s9, zero, _wait3 # if s9 == zero then _wait3
    sb s8, 0(s7) # save 'n'
    li s8, 101 # s8 = 'e'
_wait4: # wait until s9 != 0
    lb s10, 5(s7)
    andi s9, s10, 0b00100000
    beq s9, zero, _wait4 # if s9 == zero then _wait4
    sb s8, 0(s7) # save 'e'
    li s8, 33 # s8 = '!'
_wait5: # wait until s9 != 0
    lb s10, 5(s7)
    andi s9, s10, 0b00100000
    beq s9, zero, _wait5 # if s9 == zero then _wait5
    sb s8, 0(s7) # save '!'
end:
    ret
    beq zero, zero, end; # if zero == zero then end

.option  norvc
.text
.section .init 
# This test checks if an interrupt happens when reading in a disallowed address right above the allowed area outside of stack.
# EXPECTED BEHAVIOR:
# writes mem_ex to uart if working correctly
init:   
        nop     #hippo skipps first instruction for some reason
        la      sp, _stack_start # set stack pointer
        
        csrwi   0x300, 8                # enable global interrupts

        la      t1, _memexhandler
        srl     t1, t1, 2
        csrw    0xb08, t1               #set memexhandler jump adrs

        li      t1, 0x0400 # t1 =0x400 
        slli    t1, t1, 16      # bits 31:18 is the start/lowest address 
        addi    t1, t1, 0b111     # bits 0 is for reading enable, bit 1 is for writing enable and bits 18:2 is for the length in words. length + start address is the higher limit. all access below is granted
        csrw    0x400, t1       #entry for accessing 0x400

        la      t1, tsk0
        srl     t1, t1, 2
        csrw    0xB01, t1               # setup tsk0 address


        la      t1,  0b0111             # prio 0b01, enable, 0b1, pend 0b1
        csrw    0xB21, t1
        nop

loop: j loop
tsk0:
        li    t1, 0x400
        sw      t0, 4(t1) 
        j       terminated

terminated:                  
        li      t1, 0x6D726574 # mret
        li      t2, 0x74616E69 # tani
        li      t3, 0x00006465 # de

term:   csrw    0x51, t1     # rightmost byte of t1 to UART
        srl     t1, t1, 8    # shift rightmost byte out
        bnez    t1, term     # if we have bytes left in register, write them, else continue
inat:   csrw    0x51, t2     
        srl     t2, t2, 8    
        bnez    t2, inat     
ed:     csrw    0x51, t3     
        srl     t3, t3, 8    
        bnez    t3, ed     

        j       exit
        nop

_memexhandler:    
        li      t1, 0x5F6D656D  # _mem
        li      t2, 0x00007865  # ex

mem_:   csrw    0x51, t1     # rightmost byte of t1 to UART
        srl     t1, t1, 8    # shift rightmost byte out
        bnez    t1, mem_     # if we have bytes left in register, write them, else continue
int:    csrw    0x51, t2     # rightmost byte of t1 to UART
        srl     t2, t2, 8    # shift rightmost byte out
        bnez    t2, int     # if we have bytes left in register, write them, else continue

        j       exit
        nop

exit:   j       exit
.global 

.rodata
.global _start

.text
_start: 
    mov x0, 0b1111
    mov x1, 0xdead
    mov x2, 0xbeef
    ret

.data
hello_str: .asciz "Hello, World!\n"
hello_len: .quad 14
test_quad: .quad 0xdeadbeef
arr: .byte 1, 2, 3, 4, 5
arr_len: .quad 5


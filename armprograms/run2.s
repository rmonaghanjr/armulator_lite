.global _start

.text
add_two_nums:
	add x0, x0, x1
	ret 

_start: 
	adr x0, n1
	ldr x0, [x0] 
	adr x1, n2 
	ldr x1, [x1] 
	mov x9, lr
	bl add_two_nums
	mov lr, x9
    ret

.data
n1: .quad 10 
n2: .quad 20


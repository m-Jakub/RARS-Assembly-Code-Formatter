# Write a program displaying the longest sequence of digits found in a string

	.eqv    SYS_PRINT_STRING, 4  # System call number for printing a string
	.eqv    SYS_READ_STRING, 8   # System call number for reading a string
	.eqv    SYS_EXIT, 10         # System call number for exiting the program
	.eqv    BUFSIZE, 80          # Buffer size for reading input

# data section - stuff to put into memory
.data
prompt: .asciz "Enter string: "         # asciz - null-terminated string for the prompt
buf:    .space  BUFSIZE                 
string:	.space	BUFSIZE

# text section - program
.text
main:
        # printing prompt
        la      a0, prompt             
        li      a7, SYS_PRINT_STRING    
        ecall                           

        # reading user input
        la      a0, buf                 
        li      a1, BUFSIZE             
        li      a7, SYS_READ_STRING     
        ecall                           

        # Convert lower to uppercase
        la      t0, buf                                
        li      t2, '0'                 
        li      t3, '9'                 
        li	t6, 0
        li	t4, 0
        
loop:
	lbu     t1, 0(t0)  
        beq	t1, zero, prefin
        bltu    t1, t2, newlongest       
        bgtu    t1, t3, newlongest        

        addi	t4, t4, 1
        b       nextchar               
        
reset:
	li	t4, 0
	b	nextchar
	
newlongest:
	bgtu	t4, t6, assignment
	b	reset
	
assignment:

	mv	t6, t4
	mv	t5, t0
	
	b	reset

nextchar:
	addi    t0, t0, 1              
	b	loop

prefin:
	sub	t5, t5, t6
	li	t4, 0
	la	t0, string
	b	fin_loop

fin_loop:
	bgeu	t4, t6, fin
	lbu     t1, 0(t5)  
	sb	t1, 0(t0)
	addi	t5, t5, 1
	addi	t0, t0, 1
	addi	t4, t4, 1
	b	fin_loop
	

fin:
	sb      zero, 0(t0)  
        la      a0, string                 
        li      a7, SYS_PRINT_STRING    
        ecall                           

        li      a7, SYS_EXIT            
        ecall                           

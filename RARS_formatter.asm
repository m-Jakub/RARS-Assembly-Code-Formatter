# 14.Write a formatting program for assembly source files, compatible with RARS assembly 
# language. The formatter should process the assembly source file by aligning it into three 
# standard columns, using HT codes; it should also remove unnecessary spaces, leaving 
# single spaces (between arguments) or replacing them with tabs.
	
	.eqv SYS_PRINT_STRING, 4
	.eqv SYS_GET_CWD, 17
	.eqv SYS_OPEN_FILE, 1024
	.eqv SYS_READ_FILE, 63
	.eqv SYS_WRITE_FILE, 64
	.eqv SYS_EXIT, 10
	.eqv SYS_CLOSE_FILE, 57
	.eqv buf_size, 512

	.data
input_file:	.asciz "source.asm"	# Input file name
output_file:	.asciz "formatted_source.asm"	# Output file name
input_buffer:	.space buf_size	# Buffer to store chunks of the file content
output_buffer:	.space buf_size	# Buffer for chunks of formatted output
line_buffer:	.space 256

	.text
main:
	# Open the input file for reading
	la	a0, input_file	# Load input file name to a0
	li	a1, 0	# Mode 0 = read
	li	a7, SYS_OPEN_FILE	# Syscall for opening a file, calling it will overwrite a0 with a descriptor (ID) of the file
	ecall
	mv	s4, a0	# Store the file descriptor in s4

	# Open the output file for writing
	la	a0, output_file	# Load output file name to a0
	li	a1, 9	# Mode 9 = write append
	li	a7, SYS_OPEN_FILE	# Syscall for opening a file, calling it will overwrite a0 with a descriptor (ID) of the file
	ecall
	mv	s10, a0	# Store the file descriptor in s10
	
	call	refill_input
	
	la	s11, output_buffer	# Reset the output buffer pointer

	li	t3, ' '
	li	t4, '\t'
	li	t5, ':'	# colon indicates lines beggining with a label
	li	s0, '#'
	li	s2, ','
	li	s3, '\n'
	
read_line:
	la	s8, line_buffer	# Load the address of the line buffer into s8

# Process the content line by line
read_line_loop:
	call	getc
	bltz	s5, exit	# If the end of the file is reached, exit the program

	# Copy the byte to the line buffer
	sb	s7, 0(s8)	# Store the byte in the line buffer
	addi	s8, s8, 1	# Increment the line buffer pointer
	bne	s7, s3, read_line_loop	# If s7 is not a newline character, continue reading the line

	sb	zero, (s8)	# Null-terminate the line
	la	s8, line_buffer	# Reset the line buffer pointer

# Check if the line starts with a label
process_line:
	lbu	t0, 0(s8)	# Load a byte from the line buffer into t0
	addi	s8, s8, 1	# Increment the line buffer pointer

	beq	t0, t5, reset_line_buffer	# If t0 is a colon, ommit the tab before the label
	
	# If null indicator found
	bnez	t0, process_line	# If t0 is not null, continue to next byte

	# If the line does not start with a label, add a tab before the instruction
add_tab_before_instruction:
	li	s9, '\t'	# Load a tab into s9
	call putc

reset_line_buffer:
	la	s8, line_buffer	# Reset the line buffer pointer

# Skip leading spaces and tabs before the label
skip_leading_spaces:
	lbu	t0, 0(s8)	# Load a byte from the line buffer into t0
	addi	s8, s8, 1	# Increment the line buffer pointer
	beq	t0, s0, space_before_hashtag	# If t0 is a hashtag, go to the second column
	beq	t0, t3, skip_leading_spaces	# Skip leading spaces
	beq	t0, t4, skip_leading_spaces	# Skip leading tabs

	mv	s9, t0	# Load the character into s9
	call	putc

# Copy the label to the output buffer
first_column:
	lbu	t0, 0(s8)
	beqz	t0, read_line	# End of line reached, go back to reading the next line
	addi	s8, s8, 1
	
	# If space or tab is found, go to next column
	beq	t0, t3, add_tab_after_first_column	# If t0 is a space, skip to the next column
	beq	t0, t4, add_tab_after_first_column	# If t0 is a tab, skip to the next column
	mv	s9, t0	# Load the character into s9
	call	putc
	j	first_column

	# Store a tab after the first column
add_tab_after_first_column:
	li	s9, '\t'	# Load a tab into s9
	call	putc

# Skip leading spaces and tabs after the colon
skip_spaces_after_first_column:
	lbu	t0, 0(s8)	# Load a byte from the line buffer into t0
	beqz	t0, read_line	# End of line reached, go back to reading the next line
	addi	s8, s8, 1	# Increment the line buffer pointer
	beq 	t0, t3, skip_spaces_after_first_column	# Skip spaces
	beq 	t0, t4, skip_spaces_after_first_column	# Skip tabs

	# Copy the first found character after the tab to the output buffer
	mv	s9, t0	# Load the character into s9
	call	putc

second_column:
	lbu	t0, 0(s8)
	lbu	t1, 1(s8)
	addi	s8, s8, 1
	beqz	t0, read_line	# End of line reached, go back to reading the next line
	beq	t1, s0, hashtag_found
	beq	t1, s2, comma_found
	mv	s9, t0	# Load the character into s9
	call	putc
	beq	t0, t4, skip_multiple_spaces	# If t0 is a tab, go to skip_multiple_spaces
	bne	t0, t3, second_column	# If t0 is a space, go to skip_multiple_spaces

skip_multiple_spaces:
	lbu	t0, 0(s8)
	lbu	t1, 1(s8)
	addi	s8, s8, 1
	beqz	t0, read_line	# End of line reached, go back to reading the next line
	beq	t1, s0, hashtag_found
	beq	t1, s2, comma_found
	beq	t0, t3, skip_multiple_spaces	# Skip spaces
	beq	t0, t4, skip_multiple_spaces	# Skip tabs
	mv	s9, t0	# Load the character into s9
	call	putc
	j	second_column

comma_found:
	beq	t3, t0, space_before_comma
	beq	t4, t0, space_before_comma
	mv	s9, t0
	call	putc
	lbu	t6, 0(s8)
	beq	t6, t3, second_column
	li	s9, ' '
	call	putc
	j	second_column

space_before_comma:
	li 	s9, ','
	call	putc
	beq	t6, t3, second_column
	li	s9, ' '
	call	putc
	j	second_column


hashtag_found:
	beq	t3, t0, space_before_hashtag	# If there is a space before the hashtag, replace it with a tab
	beq	t4, t0, space_before_hashtag	# If there is a tab before the hashtag

	mv	s9, t0	# Load the character into s9
	call	putc

space_before_hashtag:
	li	s9, '\t'	# Store the tab in s9
	call	putc
	li 	s9, '#'
	call	putc
	addi	s8, s8, 1	# Increment the line buffer pointer
	bnez	t0, second_column

exit:

	# Null-terminate the output buffer
	sb	zero, (s11)

	# Close the input file
	mv	a0, s4
	li	a7, SYS_CLOSE_FILE
	ecall

	# Close the output file
	mv	a0, s10
	li	a7, SYS_CLOSE_FILE
	ecall

	# Exit the program
	li	a7, SYS_EXIT
	ecall

getc:
	lb	s7, 0(s1)	# Load a byte from the input buffer into s7
	beqz	s7, refill_input	# If s7 is null, refill the input buffer
	addi	s1, s1, 1	# Increment the input buffer pointer

	# print the character for debugging
	mv	a0, s7
	li	a7, 11
	ecall

	ret
	

refill_input:
	mv	a0, s4
	la	a1, input_buffer
	li	a2, buf_size
	addi	a2, a2, -1
	li	a7, SYS_READ_FILE
	ecall

	la	s1, input_buffer	# Load the address of the input buffer into s12

	bgtz	a0, refill_done
	li	s5, -1
        ret

refill_done:
	la	s6, input_buffer	# Reset the input buffer pointer
	add	s6, s6, a0	# Add the number of bytes read to the input buffer pointer
	sb	zero, 0(s6)	# TO BE CHANGED
	lb	s7, (a1)	# Load the first byte from the input buffer into s7

	li	t0, buf_size
	addi	t0, t0, -2
	ble	a0, t0, last_refill_done
	
# # WORKFLOW: print the input buffer for debugging
# 	la	a0, input_buffer	# Load input buffer
# 	li	a7, SYS_PRINT_STRING	# Syscall to print string
# 	ecall

	ret

last_refill_done:
	addi	s6, s6, -1
	bne	s6, s1, add_newline_character
	ebreak
	ret

add_newline_character:
	addi	s6, s6, 1
	sb	s1, 0(s6)
	addi	s6, s6, 1
	sb	zero, 0(s6)
	ret

putc:
	sb	s9, 0(s11)	# Store the character in the output buffer
	addi	s11, s11, 1	# Increment the output buffer pointer
	
	la	t0, output_buffer	# Load the address of the output buffer
	addi	t0, t0, buf_size	# Compute the end address of the output buffer
	beq	s11, t0, flush_output	# If the output buffer is full, flush it

	ret

flush_output:

	la	s11, output_buffer	# Reset the output buffer pointer
	
	mv	a0, s10	# File descriptor
	la	a1, output_buffer	# Load the address of the output buffer
	li	a2, buf_size	# Load the size of the output buffer
	li	a7, SYS_WRITE_FILE	# Syscall number for writing a file
	ecall

	# # WORKFLOW: print the formatted content for debugging
	# la	a0, output_buffer	# Load output buffer
	# li	a7, SYS_PRINT_STRING	# Syscall to print string
	# ecall

	ret

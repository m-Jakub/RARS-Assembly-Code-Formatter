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
output_buffer:	.space 16384	# Buffer for chunks of formatted output
line_buffer:	.space 256	# Buffer for a single line

	.text
main:
	# Open the input file for reading
	la	a0, input_file	# Load input file name to a0
	li	a1, 0	# Mode 0 = read
	li	a7, SYS_OPEN_FILE	# Syscall for opening a file, calling it will overwrite a0 with a descriptor (ID) of the file
	ecall
	mv	s4, a0	# Store the file descriptor in s4

	call	refill_input

	la	t2, output_buffer	# Load the address of the output buffer into t2
	li	t3, ' '
	li	t4, '\t'
	li	t5, ':'	# colon indicates lines beggining with a label
	li	s0, '#'
	li	s1, '\n'
	li	s2, ','
	
read_line:
	la	s8, line_buffer	# Load the address of the line buffer into s8

# Process the content line by line
read_line_loop:
	call	getc
	bltz	s5, exit	# If the end of the file is reached, exit the program

	# Copy the byte to the line buffer
	sb	s7, 0(s8)	# Store the byte in the line buffer
	addi	s8, s8, 1	# Increment the line buffer pointer
	bne	s7, s1, read_line_loop	# If t0 is newline, process the line

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
	sb	t4, 0(t2)	# Store a tab before the instruction
	addi	t2, t2, 1	# Increment the output buffer pointer

reset_line_buffer:
	la	s8, line_buffer	# Reset the line buffer pointer

# Skip leading spaces and tabs before the label
skip_leading_spaces:
	lbu	t0, 0(s8)	# Load a byte from the line buffer into t0
	addi	s8, s8, 1	# Increment the line buffer pointer
	beq	t0, s0, comment_only_line_found
	beq	t0, t3, skip_leading_spaces	# Skip leading spaces
	beq	t0, t4, skip_leading_spaces	# Skip leading tabs

	sb	t0, 0(t2)
	addi	t2, t2, 1

# Copy the label to the output buffer
first_column:
	lbu	t0, 0(s8)
	beqz	t0, read_line	# End of line reached, go back to reading the next line
	addi	s8, s8, 1
	
	# If space or tab is found, go to next column
	beq	t0, t3, add_tab_after_first_column	# If t0 is a space, skip to the next column
	beq	t0, t4, add_tab_after_first_column	# If t0 is a tab, skip to the next column
	sb	t0, 0(t2)
	addi	t2, t2, 1
	j	first_column

	# Store a tab after the first column
add_tab_after_first_column:
	sb	t4, 0(t2)
	addi	t2, t2, 1

# Skip leading spaces and tabs after the colon
skip_spaces_after_first_column:
	lbu	t0, 0(s8)	# Load a byte from the line buffer into t0
	beqz	t0, read_line	# End of line reached, go back to reading the next line
	addi	s8, s8, 1	# Increment the line buffer pointer
	beq 	t0, t3, skip_spaces_after_first_column	# Skip spaces
	beq 	t0, t4, skip_spaces_after_first_column	# Skip tabs

	# Copy the first found character after the tab to the output buffer
	sb	t0, 0(t2)
	addi	t2, t2, 1

second_column:
	lbu	t0, 0(s8)
	addi	s8, s8, 1
	beqz	t0, read_line	# End of line reached, go back to reading the next line
	beq	t0, s0, hashtag_found
	beq	t0, s2, comma_found
	sb	t0, 0(t2)
	addi	t2, t2, 1
	beq	t0, t4, skip_multiple_spaces	# If t0 is a tab, go to skip_multiple_spaces
	bne	t0, t3, second_column	# If t0 is a space, go to skip_multiple_spaces

skip_multiple_spaces:
	lbu	t0, 0(s8)
	addi	s8, s8, 1
	beqz	t0, read_line	# End of line reached, go back to reading the next line
	beq	t0, s0, hashtag_found
	beq	t0, s2, comma_found
	beq	t0, t3, skip_multiple_spaces	# Skip spaces
	beq	t0, t4, skip_multiple_spaces	# Skip tabs
	sb	t0, 0(t2)
	addi	t2, t2, 1
	j	second_column

comma_found:
	lbu	t6, -1(t2)
	beq	t6, t3, space_before_comma
	beq	t6, t4, space_before_comma
	sb	s2, 0(t2)
	addi	t2, t2, 1
	lbu	t6, 0(s8)
	beq	t6, t3, second_column
	sb	t3, 0(t2)	# Store a space after the comma
	addi	t2, t2, 1
	j	second_column

space_before_comma:
	sb	s2, -1(t2)	# Replace the space or tab with a comma
	lbu	t6, 0(s8)
	beq	t6, t3, second_column
	sb	t3, 0(t2)	# Store a space after the comma
	addi	t2, t2, 1
	j	second_column


space_before_hashtag:
	sb	t4, -1(t2)	# Replace the space with a tab
	j	comment_only_line_found

hashtag_found:
	# load t6 with t2 - 1, to check if there is a space before the hashtag
	lbu	t6, -1(t2)
	beq	t3, t6, space_before_hashtag	# If there is a space before the hashtag, replace it with a tab
	beq	t4, t6, space_before_hashtag	# If there is a tab before the hashtag
	sb	t4, 0(t2)	# Store a tab before the hashtag
	addi	t2, t2, 1

comment_only_line_found:
	sb	s0, 0(t2)
	addi	t2, t2, 1
	bnez	t0, second_column

exit:
	# Null-terminate the output buffer
	sb	zero, (t2)	# Null-terminate the output buffer

	# WORKFLOW: print the input buffer for debugging
	la	a0, input_buffer	# Load input buffer
	li	a7, SYS_PRINT_STRING	# Syscall to print string
	ecall
	
	# WORKFLOW: print the formatted content for debugging
	la	a0, output_buffer	# Load output buffer
	li	a7, SYS_PRINT_STRING	# Syscall to print string
	ecall

	# Close the input file
	li	a7, SYS_CLOSE_FILE
	ecall

	# Open the output file for writing
	la	a0, output_file	# Load output file name to a0
	li	a1, 1	# Mode 1 = write
	li	a7, SYS_OPEN_FILE	# Syscall for opening a file, calling it will overwrite a0 with a descriptor (ID) of the file
	ecall

	# Write the formatted content to the output file
	la	a1, output_buffer
	li	a2, 16384
	li	a7, SYS_WRITE_FILE
	ecall

	# Close the output file
	li	a7, SYS_CLOSE_FILE
	ecall

	# Exit the program
	li	a7, SYS_EXIT
	ecall

getc:
	lb	s7, 0(a1)	# Load a byte from the input buffer into t0
	beqz	s7, refill_input	# If t0 is null, refill the input buffer
	addi	a1, a1, 1	# Increment the input buffer pointer
	ret
	

refill_input:
	mv	a0, s4
	la	a1, input_buffer
	li	a2, buf_size
	addi	a2, a2, -1
	li	a7, SYS_READ_FILE
	ecall

	bgtz	a0, refill_done
	li	s5, -1
        ret

refill_done:
	la	s6, input_buffer	# Reset the input buffer pointer
	add	s6, s6, a0	# Add the number of bytes read to the input buffer pointer
	sb	zero, 0(s6)	# TO BE CHANGED
	lb	s7, (a1)	# Load the first byte from the input buffer into t0
	ret
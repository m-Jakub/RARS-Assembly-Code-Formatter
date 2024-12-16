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

	.data
input_file:	.asciz "source.asm"	# Input file name
output_file:	.asciz "formatted_source.asm"	# Output file name
input_buffer:	.space 1024	# Buffer to store file content
output_buffer:	.space 1024	# Buffer for formatted output
line_buffer:	.space 256	# Buffer for a single line

# For debugging:
cwd_buffer:	.space 256	# Buffer to store current working directory
error_msg:	.asciz "Error opening file\n"	# Error message

	.text
main:
	# Open the input file for reading
	la	a0, input_file	# Load input file name to a0
	li	a1, 0	# Mode 0 = read
	li	a7, SYS_OPEN_FILE	# Syscall for opening a file, calling it will overwrite a0 with a descriptor (ID) of the file
	ecall

	# Read from the file into input_buffer (it takes the file descriptor from a0, so don't need to load it again)
	la	a1, input_buffer	# Address of the input buffer
	li	a2, 1024	# Max bytes to read
	li	a7, SYS_READ_FILE	# Syscall for reading a file
	ecall

	la	t2, output_buffer
	li	t3, ' '
	li	t4, '\t'
	li	t5, ':'	# colon indicates lines beggining with a label
	li	s2, ','
	li	s1, '\n'
	li	s0, '#'

read_line:
	la	t1, line_buffer	# Load the address of the line buffer into t1

# Process the content line by line
read_line_loop:
	# Check if end of file or newline is reached
	lbu	t0, 0(a1)	# Load a byte from the input buffer into t0
	addi	a1, a1, 1
	beqz	t0, exit	# End of file (buffer) reached

	# Copy the byte to the line buffer
	sb	t0, (t1)	# Store the byte in the line_buffer
	addi	t1, t1, 1	# Increment the line buffer pointer
	bne	t0, s1, read_line_loop	# If t0 is newline, process the line

	sb	zero, (t1)	# Null-terminate the line
	la	t1, line_buffer	# Reset the line buffer pointer

# Check if the line starts with a label
process_line:
	lbu	t0, 0(t1)	# Load a byte from the line buffer into t0
	addi	t1, t1, 1	# Increment the line buffer pointer

	beq	t0, t5, reset_line_buffer	# If t0 is a colon, ommit the tab before the label
	
	# If null indicator found
	bnez	t0, process_line	# If t0 is not null, continue to next byte

	# If the line does not start with a label, add a tab before the instruction
add_tab_before_instruction:
	sb	t4, 0(t2)	# Store a tab before the instruction
	addi	t2, t2, 1	# Increment the output buffer pointer

reset_line_buffer:
	la	t1, line_buffer	# Reset the line buffer pointer

# Skip leading spaces and tabs before the label
skip_leading_spaces:
	lbu	t0, 0(t1)	# Load a byte from the line buffer into t0
	addi	t1, t1, 1	# Increment the line buffer pointer
	beq	t0, s0, comment_only_line_found
	beq	t0, t3, skip_leading_spaces	# Skip leading spaces
	beq	t0, t4, skip_leading_spaces	# Skip leading tabs

	sb	t0, 0(t2)
	addi	t2, t2, 1

# Copy the label to the output buffer
first_column:
	lbu	t0, 0(t1)
	beqz	t0, read_line	# End of line reached, go back to reading the next line
	addi	t1, t1, 1
	
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
	lbu	t0, 0(t1)	# Load a byte from the line buffer into t0
	beqz	t0, read_line	# End of line reached, go back to reading the next line
	addi	t1, t1, 1	# Increment the line buffer pointer
	beq 	t0, t3, skip_spaces_after_first_column	# Skip spaces
	beq 	t0, t4, skip_spaces_after_first_column	# Skip tabs

	# Copy the first found character after the tab to the output buffer
	sb	t0, 0(t2)
	addi	t2, t2, 1

second_column:
	lbu	t0, 0(t1)
	addi	t1, t1, 1
	beqz	t0, read_line	# End of line reached, go back to reading the next line
	beq	t0, s0, hashtag_found
	beq	t0, s2, comma_found
	sb	t0, 0(t2)
	addi	t2, t2, 1
	beq	t0, t4, skip_multiple_spaces	# If t0 is a tab, go to skip_multiple_spaces
	bne	t0, t3, second_column	# If t0 is a space, go to skip_multiple_spaces

skip_multiple_spaces:
	lbu	t0, 0(t1)
	addi	t1, t1, 1
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
	lbu	t6, 0(t1)
	beq	t6, t3, second_column
	sb	t3, 0(t2)	# Store a space after the comma
	addi	t2, t2, 1
	j	second_column

space_before_comma:
	sb	s2, -1(t2)	# Replace the space or tab with a comma
	lbu	t6, 0(t1)
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
	li	a2, 1024
	li	a7, SYS_WRITE_FILE
	ecall

	# Close the output file
	li	a7, SYS_CLOSE_FILE
	ecall

	# Exit the program
	li	a7, SYS_EXIT
	ecall

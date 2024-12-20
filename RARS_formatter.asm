	# 14.Write a formatting program for assembly source files, compatible with RARS assembly
	# language. The formatter should process the assembly source file by aligning it into three
	# standard columns, using HT codes; it should also remove unnecessary spaces, leaving
	# single spaces (between arguments) or replacing them with tabs.
	
	.eqv	SYS_PRINT_STRING, 4
	.eqv	SYS_GET_CWD, 17
	.eqv	SYS_OPEN_FILE, 1024
	.eqv	SYS_READ_FILE, 63
	.eqv	SYS_WRITE_FILE, 64
	.eqv	SYS_EXIT, 10
	.eqv	SYS_CLOSE_FILE, 57
	.eqv	SYS_READ_STRING, 8
	.eqv	buf_size, 512
	
	.data
input_file_prompt:	.asciz	"Enter input file name: "
output_file_prompt:	.asciz	"Enter output file name: "
input_file:	.space	64	# Adjust size based on expected file name length
output_file:	.space	64
input_buffer:	.space	buf_size	# Buffer to store chunks of the file content
output_buffer:	.space	buf_size	# Buffer for chunks of formatted output
line_buffer:	.space	256
	
	.text
main:	
	call	prompt_user	# Prompt the user for input and output file names
	
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
	addi	s1, s1, -1	# Decrement the input buffer pointer to prevent skipping the first character
	
	la	s11, output_buffer	# Reset the output buffer pointer
	
	li	t3, ' '
	li	t4, '\t'
	li	t5, ':'	# colon indicates lines beggining with a label
	li	s0,'#'
	li	s2,','
	li	s3, '\n'
	
read_line:	
	la	s8, line_buffer	# Load the address of the line buffer into s8
	
	# Process the content line by line
read_line_loop:	
	call	getc
	li	t0, -1
	beq	s7, t0, exit	# If the end of the file is reached, exit the program
	
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
	
	beq	t0, t5, reset_line_buffer	# If t0 is a colon, reset line buffer
	bnez	t0, process_line	# If t0 is not null, continue to the next byte
	
reset_line_buffer:	
	la	s8, line_buffer
	beqz	t0, add_tab_before_instruction	# If t0 is not null (meaning the zero column contains the label), process zero column
	
skip_leading_spaces:	
	lbu	t0, 0(s8)	# Load a byte from the line buffer into t0
	addi	s8, s8, 1	# Increment the line buffer pointer
	beq	t0, s0, hashtag_found	# If t0 is a hashtag, go to the second column
	beq	t0, t3, skip_leading_spaces	# Skip leading spaces
	beq	t0, t4, skip_leading_spaces	# Skip leading tabs
	addi	s8, s8, -1	# Decrement the line buffer pointer to process the first character of the first column

zero_column_loop:	# Only the label is processed in the zero column
	lbu	t0, 0(s8)
	addi	s8, s8, 1

	beq	t0, t3, zero_column_loop	# Skip spaces between the label name and the colon
	beq	t0, t4, zero_column_loop	# Skip tabs between the label name and the colon
	
	addi	sp, sp, -4
	sw	t0, 0(sp)
	
	mv	s9, t0	# Load the character into s9 to put it in the output buffer
	call	putc
	
	lw	t0, 0(sp)
	addi	sp, sp, 4
	
	bne	t0, t5, zero_column_loop	# If t0 is not a colon, continue to the next byte
	
add_tab_before_instruction:	
	li	s9, '\t'	# Load a tab into s9
	call	putc
	
	# Skip leading spaces and tabs before the label
skip_spaces_before_first_column:	
	lbu	t0, 0(s8)	# Load a byte from the line buffer into t0
	lbu	t1, 1(s8)	# Load the next byte from the line buffer into t1
	addi	s8, s8, 1	# Increment the line buffer pointer
	beq	t0, s0, hashtag_found	# If t0 is a hashtag, go to the second column
	beq	t0, t3, skip_spaces_before_first_column	# Skip leading spaces
	beq	t0, t4, skip_spaces_before_first_column	# Skip leading tabs
	
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
	beq	t0, t3, skip_spaces_after_first_column	# Skip spaces
	beq	t0, t4, skip_spaces_after_first_column	# Skip tabs
	
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
	
	beq	t0, t4, skip_multiple_spaces	# If t0 is a tab, go to skip_multiple_spaces
	beq	t0, t3, skip_multiple_spaces	# If t0 is a space, go to skip_multiple_spaces
	
	mv	s9, t0	# Load the character into s9
	call	putc
	
	j	second_column
	
skip_multiple_spaces:	
	addi	s8, s8, -1
	
skip_multiple_spaces_loop:	
	lbu	t0, 0(s8)
	lbu	t1, 1(s8)
	addi	s8, s8, 1
	beqz	t0, read_line	# End of line reached, go back to reading the next line
	beq	t1, s0, hashtag_found
	beq	t1, s2, comma_found
	beq	t1, s3, second_column	# If t0 is a newline, go to back the second_column processing
	beq	t0, t3, skip_multiple_spaces_loop	# Skip spaces
	beq	t0, t4, skip_multiple_spaces_loop	# Skip tabs
	
	addi	sp, sp, -4
	sw	t0, 0(sp)
	
	li	s9, ' '
	call	putc
	
	lw	t0, 0(sp)
	addi	sp, sp, 4
	
	mv	s9, t0	# Load the character into s9
	call	putc
	j	second_column
	
comma_found:	
	beq	t3, t0, space_before_comma
	beq	t4, t0, space_before_comma
	mv	s9, t0	# If the character before the comma is not a space or tab, load it into s9
	call	putc
	
space_before_comma:	
	li	s9, ','
	call	putc
	addi	s8, s8, 1
	lbu	t6, 0(s8)	# Load the character after the comma into t6
	beq	t6, t3, second_column
	li	s9, ' '
	call	putc
	j	second_column
	
hashtag_found:	
	beq	s0, t0, line_starts_with_hashtag	# hashtag
	beq	t3, t0, space_before_hashtag	# space
	beq	t4, t0, space_before_hashtag	# tab
	
	mv	s9, t0	# Load the character into s9
	call	putc
	
space_before_hashtag:	
	li	s9, '\t'	# Store the tab in s9
	call	putc
	j	second_column
	
line_starts_with_hashtag:	
	li	s9,'#'
	call	putc
	j	second_column
	
exit:	
	sb	zero, 0(s11)	# Null-terminate the output buffer
	call	flush_output
	
	# Close the input file
	mv	a0, s4
	li	a7, SYS_CLOSE_FILE
	ecall
	
	# Close the output file
	mv	a0, s10
	li	a7, SYS_CLOSE_FILE
	ecall
	
	li	a7, SYS_EXIT
	ecall
	
getc:	
	lb	s7, 0(s1)	# Load a byte from the input buffer into s7
	beqz	s7, refill_input	# If s7 is null, refill the input buffer
	addi	s1, s1, 1	# Increment the input buffer pointer

	ret
	
empty_input_buffer:	
	li	s7, -1
	ret
	
refill_input:	
	mv	a0, s4
	la	a1, input_buffer
	li	a2, buf_size
	addi	a2, a2, -1
	li	a7, SYS_READ_FILE
	ecall
	
	la	s1, input_buffer	# Load the address of the input buffer into s12
	beqz	a0, empty_input_buffer	# If a0 is0, the input buffer is empty
	
refill_done:	
	la	s6, input_buffer	# Reset the input buffer pointer
	add	s6, s6, a0	# Add the number of bytes read to the input buffer pointer
	sb	zero, 0(s6)	# TO BE CHANGED
	
	la	s1, input_buffer	# Load the address of the input buffer into s1
	lb	s7, 0(s1)	# Load a byte from the input buffer into s7
	addi	s1, s1, 1	# Increment the input buffer pointer
	
	li	t0, buf_size
	addi	t0, t0, -2
	ble	a0, t0, last_refill_done
	
	ret
	
last_refill_done:	
	addi	s6, s6, -1
	bne	s6, s1, add_newline_character
	ret
	
add_newline_character:	
	addi	s6, s6, 1
	sb	s3, 0(s6)
	addi	s6, s6, 1
	sb	zero, 0(s6)
	ret
	
putc:	
	sb	s9, 0(s11)	# Store the character in the output buffer
	addi	s11, s11, 1	# Increment the output buffer pointer
	
	la	t0, output_buffer	# Load the address of the output buffer
	addi	t0, t0, buf_size	# Calculate the end of the output buffer
	beq	s11, t0, flush_output	# If the output buffer is full, flush it
	
	ret
	
flush_output:	
	mv	t0, s11	# Store the output buffer pointer in t0
	la	s11, output_buffer	# Reset the output buffer pointer
	
	mv	a0, s10	# File descriptor
	la	a1, output_buffer	# Load the address of the output buffer
	sub	a2, t0, s11	# Calculate the number of bytes to write
	li	a7, SYS_WRITE_FILE	# Syscall number for writing a file
	ecall

	# print the output buffer for debugging
	la	a0, output_buffer
	li	a7, SYS_PRINT_STRING
	ecall
	ret
	
prompt_user:	
	# Print "Enter input file name:	"
	la	a0, input_file_prompt
	li	a7, SYS_PRINT_STRING
	ecall
	
	# Read input file name
	la	a0, input_file
	li	a1, 64	# Maximum length of the file name
	li	a7, SYS_READ_STRING
	ecall
	
	# Print "Enter output file name:	"
	la	a0, output_file_prompt
	li	a7, SYS_PRINT_STRING
	ecall
	
	# Read output file name
	la	a0, output_file
	li	a1, 64	# Maximum length of the file name
	li	a7, SYS_READ_STRING
	ecall
	
	addi	sp, sp, -4
	sw	ra, 0(sp)
	
	# Remove newline character from input file name
	la	a0, input_file
	call	remove_newline
	
	# Remove newline character from output file name
	la	a0, output_file
	call	remove_newline
	
	lw	ra, 0(sp)
	addi	sp, sp, 4
	
	ret
	
remove_newline:	
	lbu	t0, 0(a0)
	beqz	t0, ret_nl
	addi	a0, a0, 1
	li	t1, '\n'
	bne	t0, t1, remove_newline
	addi	a0, a0, -1
	sb	zero, 0(a0)
ret_nl:	
	ret
	

	.eqv SYS_PRINT_STRING, 4
	.eqv SYS_GET_CWD, 17
	.eqv SYS_OPEN_FILE, 1024
	.eqv SYS_READ_FILE, 63
	.eqv SYS_WRITE_FILE, 64
	.eqv SYS_EXIT, 10

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

	# WORKFLOW (for debugging): print the content of the input file
	# la	a0, input_buffer	# Load input buffer
	# li	a7, SYS_PRINT_STRING	# Syscall to print string
	# ecall
	# j	exit

# Process the content line by line
read_line:
	# Check if end of file or newline is reached
	la	t1, line_buffer	# Load/reset the address of the line buffer into t1
	lbu	t0, 0(a1)	# Load a byte from the input buffer into t0
	li	t2, '\n'	# Load newline character into t2
	beqz	t0, process_line	# End of file (buffer) reached
	beq	t0, t2, process_line	# If t0 is newline, process the line

	# Copy the byte to the line buffer
	sb	t0, (t1)	# Store the byte in the line_buffer
	addi	a1, a1, 1	# Increment the input buffer pointer
	addi	t1, t1, 1	# Increment the line buffer pointer
	j	read_line

process_line:
	sb	zero, (t1)	# Null-terminate the line
	la	t1, line_buffer	# Reset the line buffer pointer

	la	t2, '\t'
	la 	t3, output_buffer
	la	t4, ':'	# colon indicates lines beggining with a label
	la	t5, ' '

	# WORKFLOW (for debugging): print the content of the line
	# la	a0, line_buffer	# Load line buffer
	# li	a7, SYS_PRINT_STRING	# Syscall to print string
	# ecall
	# j	exit

	# Check if the line starts with a label
find_label:
	lbu	t0, 0(t1)	# Load a byte from the line buffer into t0
	addi	t1, t1, 1	# Increment the line buffer pointer
	beqz	t0, copy_instruction	# Colon not found, proceed with the line identification
	beqz	t0, exit	# End of file reached
	bne	t0, t4, find_label	# If t0 is not colon, continue to next byte
	
	# when the colon is found, the line is a label, so it goes to the process_label_line

	# Copy the label to the output buffer
	la	t1, line_buffer	# Reset the line buffer pointer
	la	t2, output_buffer	# Load the output buffer pointer
	la	t3, ' '	# Load space character into t3
	la	t4, '\t'	# Load tab character into t4
	la	t5, ':'	# Load colon character into t5

first_column:
	lbu	t6, 0(t1)	# Load a byte from the line buffer into t0
	beqz	t6, read_line	# End of label reached, go back to reading the next line
	beq	t6, ' ', first_column	# Skip leading spaces
	beq	t6, '\t', first_column	# Skip leading tabs
	sb	t6, 0(t2)	# Store the byte in the output buffer
	addi	t1, t1, 1	# Increment the line buffer pointer
	addi	t2, t2, 1	# Increment the output buffer pointer
	bne	t6, t5, first_column	# If t6 is not colon, continue to next byte

	# If colon is found
	sb	t5, 0(t2)	# Store the colon in the output buffer
	addi	t2, t2, 1	# Increment the output buffer pointer
	sb	t4, 0(t2)	# Store a tab in the output buffer
	addi	t2, t2, 1	# Increment the output buffer pointer

# Copy the rest of the line after the colon
rest_of_line:
	addi	t1, t1, 1	# Increment the line buffer pointer
	lbu	t6, 0(t1)	# Load a byte from the line buffer into t6
	beqz	t6, read_line	# End of line reached, go back to reading the next line




copy_instruction:
	
	

exit:
	li	a7, SYS_EXIT	# Syscall to exit
	ecall

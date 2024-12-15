.eqv SYS_PRINT_STRING, 4
.eqv SYS_GET_CWD, 17
.eqv SYS_OPEN_FILE, 1024
.eqv SYS_READ_FILE, 63
.eqv SYS_WRITE_FILE, 64
.eqv SYS_EXIT, 10

.data
input_file:	.asciz "source.asm"			# Input file name
output_file:	.asciz "formatted_source.asm"		# Output file name
input_buffer:	.space 1024				# Buffer to store file content
output_buffer:	.space 1024				# Buffer for formatted output
line_buffer:	.space 256				# Buffer for a single line
tab:		.asciz "\t"				# Tab character for formatting
newline:	.asciz "\n"				# Newline character

cwd_buffer:	.space 256				# Buffer to store current working directory

# For debugging:
error_msg:	.asciz "Error opening file\n"		# Error message

.text
.globl main

main:
# WORKFLOW: Get the current working directory and print it
	# la	a0, cwd_buffer				# Load address of the buffer to store CWD
	# li	a1, 256					# Length of the buffer
	# li	a7, SYS_GET_CWD				# Syscall for getting the current working directory
	# ecall

	# la	a0, cwd_buffer				# Load address of the CWD buffer into a0
	# li	a7, SYS_PRINT_STRING			# Syscall for printing a string
	# ecall

# Open the input file for reading
	la	a0, input_file				# Load input file name to a0
	li	a1, 0					# Mode 0 = read
	li	a7, SYS_OPEN_FILE			# Syscall for opening a file, calling it will overwrite a0 with a descriptor (ID) of the file
	ecall

# WORKFLOW: check if the file is opened successfully
	# bltz	a0, file_open_error			# If a0 < 0, jump to file_open_error

# Read from the file into input_buffer (it takes the file descriptor from a0, so don't need to load it again)
	la	a1, input_buffer			# Address of the input buffer
	li	a2, 1024				# Max bytes to read
	li	a7, SYS_READ_FILE			# Syscall for reading a file
	ecall

	la	t1, line_buffer				# Load the address of the line buffer into t1

# WORKFLOW (for debugging): print the content of the input file
# 	la	a0, input_buffer			# Load input buffer
# 	li	a7, SYS_PRINT_STRING			# Syscall to print string
# 	ecall
# 	j	exit

# Process the content line by line
read_line:
# Check if end of file or newline is reached
	lbu t0, 0(a1)					# Load a byte from the input buffer into t0
	li t2, '\n'					# Load newline character into t2
	beqz t0, process_line				# End of file (buffer) reached
	beq t0, t2, process_line			# If t0 is newline, process the line

# Copy the byte to the line buffer
	sb t0, (t1)					# Store the byte in the line_buffer
	addi a1, a1, 1					# Increment the input buffer pointer
	addi t1, t1, 1					# Increment the line buffer pointer
	j read_line

process_line:
	sb zero, (t1)					# Null-terminate the line

	# WORKFLOW (for debugging): print the content of the line
	la	a0, line_buffer				# Load line buffer
	li	a7, SYS_PRINT_STRING			# Syscall to print string
	ecall
	j	exit

	# * Call line processing routine here *

	beqz t0, exit					# End of file reached
	la t1, line_buffer				# Reset the line buffer pointer
	j read_line            				# Continue to next line


# WORKFLOW: Error handling for file opening
# file_open_error:
# 	la	a0, error_msg				# Load address of error message into a0
# 	li	a7, SYS_PRINT_STRING			# Load syscall number for printing a string into a7
# 	ecall						# Make the system call


exit:
	li	a7, SYS_EXIT				# Syscall to exit
	ecall

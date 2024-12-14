.data
input_file:     .asciz "source.asm"           # Input file name
output_file:    .asciz "formatted_source.asm" # Output file name
input_buffer:   .space 1024                   # Buffer to store file content
output_buffer:  .space 1024                   # Buffer for formatted output
line_buffer:    .space 256                    # Buffer for a single line
tab:            .asciz "\t"                  # Tab character for formatting
newline:        .asciz "\n"                  # Newline character

cwd_buffer:     .space 256                    # Buffer to store current working directory

# for debugging:
error_msg:      .asciz "Error opening file\n" # Error message

.text
.globl main

main:
# Get the current working directory
    la a0, cwd_buffer          # Load address of the buffer to store CWD
    li a1, 256                 # Length of the buffer
    li a7, 17                  # Syscall for getting the current working directory
    ecall

    # Print the current working directory
    la a0, cwd_buffer          # Load address of the CWD buffer into a0
    li a7, 4                   # Syscall for printing a string
    ecall
    
    
    

    # Open the input file for reading
    la a0, input_file         	# Load input file name to a0
    li a1, 0                  	# Mode 0 = read
    li a7, 1024               	# Syscall for opening a file, calling it will overrite a0 with a descriptor (ID) of the file
    ecall
    # mv s0, a0               	# Save file descriptor in s0
    
    bltz a0, file_open_error

    # Read from the file into input_buffer
    # mv a0, s0
    # descriptor already in a0
    la a1, input_buffer       	# Address of the input buffer
    li a2, 1024               	# Max bytes to read
    li a7, 63			# Syscall for reading a file
    ecall

    # Process the content line by line
process_lines:
    # Implement line-by-line processing here
    # Extract label, instruction, arguments, and format

    # Placeholder: print each line to the console for testing
    # la a0, line_buffer        	# Load line buffer
    la a0, input_buffer        	# Load input buffer
    li a7, 4                  	# Syscall to print string
    ecall

    # Loop back or exit when done
    j exit

process_lines_done:
    # Open the output file for writing
    la a0, output_file        	# Load output file name
    li a1, 1                  	# Mode 1 = write
    li a7, 1024               	# Syscall for opening a file
    ecall
    mv s1, a0               	# Save output file descriptor in s1

    # Write the formatted content to the output file
    la a0, output_buffer      	# Address of output buffer
    li a1, 1024               	# Bytes to write
    li a7, 1024               	# Syscall for writing a file
    ecall

file_open_error:
    la a0, error_msg
    li a7, 4
    ecall
    
exit:
    # Exit
    li a7, 10                 	# Syscall to exit
    ecall
.eqv SYS_PRINT_STRING, 4
.eqv SYS_GET_CWD, 17
.eqv SYS_OPEN_FILE, 1024
.eqv SYS_READ_FILE, 63
.eqv SYS_WRITE_FILE, 64
.eqv SYS_EXIT, 10

.data
input_file:     .asciz "source.asm"           # Input file name
output_file:    .asciz "formatted_source.asm" # Output file name
input_buffer:   .space 1024                   # Buffer to store file content
output_buffer:  .space 1024                   # Buffer for formatted output
line_buffer:    .space 256                    # Buffer for a single line
tab:            .asciz "\t"                   # Tab character for formatting
newline:        .asciz "\n"                   # Newline character

cwd_buffer:     .space 256                    # Buffer to store current working directory

# for debugging:
error_msg:      .asciz "Error opening file\n" # Error message

.text
.globl main

main:
    # Get the current working directory
    la a0, cwd_buffer          # Load address of the buffer to store CWD
    li a1, 256                 # Length of the buffer
    li a7, SYS_GET_CWD         # Syscall for getting the current working directory
    ecall

    # Print the current working directory
    la a0, cwd_buffer          # Load address of the CWD buffer into a0
    li a7, SYS_PRINT_STRING    # Syscall for printing a string
    ecall

    # Open the input file for reading
    la a0, input_file          # Load input file name to a0
    li a1, 0                   # Mode 0 = read
    li a7, SYS_OPEN_FILE       # Syscall for opening a file, calling it will overwrite a0 with a descriptor (ID) of the file
    ecall
    bltz a0, file_open_error   # If a0 < 0, jump to file_open_error

    # Read from the file into input_buffer
    la a1, input_buffer        # Address of the input buffer
    li a2, 1024                # Max bytes to read
    li a7, SYS_READ_FILE       # Syscall for reading a file
    ecall

    # Process the content line by line
process_lines:
    # Implement line-by-line processing here
    # Extract label, instruction, arguments, and format

    # Placeholder: print each line to the console for testing
    la a0, input_buffer        # Load input buffer
    li a7, SYS_PRINT_STRING    # Syscall to print string
    ecall

    # Loop back or exit when done
    j exit

process_lines_done:
    # Open the output file for writing
    la a0, output_file         # Load output file name
    li a1, 1                   # Mode 1 = write
    li a7, SYS_OPEN_FILE       # Syscall for opening a file
    ecall
    mv s1, a0                  # Save output file descriptor in s1

    # Write the formatted content to the output file
    la a0, output_buffer       # Address of output buffer
    li a1, 1024                # Bytes to write
    li a7, SYS_WRITE_FILE      # Syscall for writing a file
    ecall

file_open_error:
    la a0, error_msg           # Load address of error message
    li a7, SYS_PRINT_STRING    # Syscall for printing a string
    ecall
    
exit:
    # Exit
    li a7, SYS_EXIT            # Syscall to exit
    ecall
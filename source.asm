main:
    # Open the input file for reading
    la a0, input_file         	# Load input file name to a0
    li a1, 0                  	# Mode 0 = read
    li a7, 1024               	# Syscall for opening a file, calling it will overwrite a0 with a descriptor (ID) of the file
    ecall

    # Read from the file into input_buffer
    la a1, input_buffer        # Address of the input buffer
    li a2, 1024                # Max bytes to read
    li a7, 63                  # Syscall for reading a file
    ecall
	# Test 1: Line with single comment, is indented
# Some comment

	# Test 2: (line with label) spaces before and any indentation skipped
   	main:
   	
	# Test 3: (line with instruction) spaces before the instruction instead of tab
       li	a1, 0

	# Test 4: (line with instruction) spaces after the instruction instead of tab
	li   a1, 0
	
	# Test 5: (line with instruction) multiple spaces between arguments
	li	a1,   0

	# Test 6: (line with instruction) no space after the colon
	li	a1,0
	
	# Test 7: (line with instruction) space before the colon
	li	a1 , 0
	
	# Test 8: (line with instruction) multiple space before and after the colon
	li	a1   ,    0
	
	# Test 8: (line with instruction) multiple space before and after the colon
li	a1   ,    0
	
	# test 9: (line with label) spaces instead of tab after the label
output_buffer:	.space 2048	# Buffer for formatted output
output_buf:   .space 2048	# Buffer for formatted output

	# test 10:
main:	li	a1, 0


	
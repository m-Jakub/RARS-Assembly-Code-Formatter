	# Test 1: Line with single comment, is indented
	# Some comment
	
	# Test 2: no tab before the comment
	sub	a0, a1, a2	# Inline comment
	
	# Test 3: spaces before the comment instead of tab
	sub	a0, a1, a2	# Inline comment
	
	# Test 4: multiple tabs before the comment
	sub	a0, a1, a2	# Inline comment
	
	# Test 5: spaces before the instruction instead of tab
	li	a1, 0
	
	# Test 6: spaces after the instruction instead of tab
	li	a1, 0
	
	# Test 7: multiple spaces between arguments
	li	a1, 0
	
	# Test 8: no space after the colon
	li	a1, 0
	
	# Test 9: space before the colon
	li	a1, 0
	
	# Test 10: multiple spaces before and after the colon
	li	a1, 0
	
	# Test 11: no tab before the instruction
	li	a1, 0
	
	# Test 12: spaces instead of tab after the label
output_buffer:	.space	2048	# Buffer for formatted output
output_buf:	.space	2048	# Buffer for formatted output
	
	# Test 13: spaces between label name and colon
main:	
	
	# Test 14: spaces before the label and any inproper indentation skipped
main:	
main:	
main:	
	
	# Test 15: directive with spaces instead of tabs
	.data
input_buffer:	.space	512
	
	# Test 16: no space after the colon
input_buffer:	.space	512
	
	# Test 17: all four columns separated by spaces instead of tabs
input_buffer:	.space	512	# Buffer for input
	

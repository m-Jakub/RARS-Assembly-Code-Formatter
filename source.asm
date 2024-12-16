   main:   
addi   t0,t0, 1   # Increment t0
    beq  t0,t1,  label1   # Check if t0 == t1
    j next   # Jump to next

label1:    li  t2 ,  10    # Load 10 into t2
    mul   t3 , t2, t1    # Multiply t2 and t1, store in t3   
      j end    # Jump to end

    next:   sub   t1, t1, t2   # Subtract t2 from t1
# This is a comment line without code
    j   main    # Loop back to main

end:       nop   # End of program

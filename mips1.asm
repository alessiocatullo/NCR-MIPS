	la $t0, n_articoli
	lw $t0, 0($t0)
	la $t1, cart	# Mi carico posizione dello stack
	
	li $v0, 4
	move $a0, $t0
	syscall
	
	PRINT:
		lw $t2, 0($t1)
	
		lw $t3, 0($t2)
		la $t1, 4($t2)
		
		li $v0, 4
		move $a0, $t3
		syscall
		li $v0, 11
		lb $a0, line_break
		syscall
		
		subi $t0, $t0, 1
		bgt $t0, $zero, PRINT	
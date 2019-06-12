
		la $a0, buffer
		li $a1, 0
		li $a2, 13		
		move $t8, $ra
		jal substring
		move $s0, $v0
		move $ra, $t8
		
		li $v0, 4
		move $a0, $s0
		syscall
		
		la $a0, buffer
		li $a1, 13
		li $a2, 25		
		move $t8, $ra
		jal substring
		move $s0, $v0
		move $ra, $t8
		
		li $v0, 4
		move $a0, $s0
		syscall
		
		la $a0, buffer
		li $a1, 25
		li $a2, 32		
		move $t8, $ra
		jal substring
		move $s0, $v0
		move $ra, $t8
		
		li $v0, 4
		move $a0, $s0
		syscall
		
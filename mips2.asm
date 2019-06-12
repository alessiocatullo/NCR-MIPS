		la $a0, buffer		# EAN - 13
		li $a1, 0		# START
		li $a2, 13		# END
		move $t8, $ra		# Salvo il registro $ra
		jal substring		# Effettuo la substring
		move $ra, $t8		# Recuper il registro $ra
		move $s0, $v0		# $s0 <- EAN 
		
		li $v0, 4
		move $a0, $s0
		syscall
		
		
		
		la $a0, buffer		# EAN - 13
		li $a1, 13		# START
		li $a2, 25		# END
		move $t8, $ra		# Salvo il registro $ra
		jal substring		# Effettuo la substring
		move $ra, $t8		# Recuper il registro $ra
		move $s0, $v0		# $s0 <- EAN 


######### METODI STACK ##################
articoli_push:
	move $t0, $a0 		# EAN
	move $t1, $a1		# TEXT
	move $t2, $a2		# PRIZE
	
	la $t3, articoli	# Mi carico posizione dello stack + indice stack
	lw $t4, 0($t3)
	la $t5, articoli_n

	li $v0, 9		# Creo spazio [9]
	li $a0, 32		# 4 parole * 4Byte
	syscall

	sw $t0, 0($v0)		# Salvo i valori nello spazio creato
	sw $t1, 4($v0)		
	sw $t2, 8($v0)
	sw $t4, 12($v0)		# next = *old_stack

	lw $t6, 0($t5)		
	addi $t6, $t6, 1	# incremento l'indice dello stack

	sw $v0, 0($t3)		# Aggiorno lo stack pointer al nodo appena creato
	sw $t6, 0($t5) 		# Aggiorno il contatore di elementi

	jr $ra			# FINE
	
articoli_print:
	la $t0, articoli_n
	lw $t0, 0($t0)
	beq $t0, $zero, EMPTY
	la $t1, articoli	# Mi carico posizione dello stack
	
	PRINT:
		lw $t2, 0($t1)
	
		lw $t3, 0($t2)
		lw $t4, 4($t2)		# Salvo i valori nello spazio creato
		lw $t5, 8($t2)
		la $t1, 12($t2)
		
		li $v0, 4
		move $a0, $t3
		syscall
		li $v0, 4
		move $a0, $t4
		syscall
		li $v0, 1
		move $a0, $t5
		syscall
		li $v0, 4
		la $a0, linebreak
		syscall
		
		subi $t0, $t0, 1
		bgt $t0, $zero, PRINT	
	jr $ra
	
EMPTY:
	li $v0, 4
	la $a0, errorLoadParam
	syscall
	
	li $v0, 10
	syscall


############## METODI USEFULL #####################
substring:
	move $t0, $a0		# STRINGA
	move $t1, $a1		# START
	move $t2, $a2		# END
	add $t4, $t4, $zero 
	
	move $t5, $ra
	la $a0, readFileSpace
	li $a1, 15
	jal clearBuffer
	move $ra, $t5
	
	la $a0, readFileSpace
	SCAN:
	add $t3, $t0, $t1		
	lb $t3, 0($t3)
	addi $a0, $a0, 1
	sb $t3, 0($a0)
	addi $t1, $t1, 1
	addi $t4, $t4, 1
	bne $t1, $a2, SCAN
	
	subi $t4, $t4, 1
	sub $v0, $a0, $t4
	
	jr $ra
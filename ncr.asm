.data  
	plufile: .asciiz "NCR-MIPS/plu.dat"
	buffer: .space 1024
	errorLoadParam: .asciiz "\n\nL'Anagrafica è vuota"
	ean: .asciiz "\nEAN: "
	text: .asciiz "\nDESCRIZIONE: "
	price: .asciiz "\nPREZZO: "
	temp_ean: .asciiz "8700000000003"
	temp_text: .asciiz "SALUMI VAR  "
	articoli: .word 0
	articoli_n: .word 0
	linebreak: .asciiz "\n"
	readFileSpace: .space 15
.text
################################################
main:	
	jal loadPLU
	#jal clearBuffer
	#jal loadCTL
	
	li $v0, 4
	la $a0, linebreak
	syscall
	
	#jal articoli_print
	
	li $v0, 10
	syscall             	# fine

########## LOAD PARAMS ##################
loadPLU:
	# Open plu file for reading
	li $v0, 13		# system call for open file = 13
	la $a0, plufile   	# input file name
	li $a1, 0        	# flag for reading
	syscall            	# open a file 
	move $t9, $v0      	# save the file descriptor
	
	readingPLU:
		# reading ean from first words
		li $v0, 14       	# system call for reading from file = 14
		move $a0, $t9      	# file descriptor 
		la $a1, buffer   	# address of buffer from which to read
		li $a2, 32		# hardcoded buffer length
		syscall            	# read from file
		
		beq $v0, $zero, doneReading
        	slt $t0, $v0, $zero
        	beq $t0, 1, doneReading
		
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
		
		move $t8, $ra 
		#jal articoli_push
		move $ra, $t8
		
		j readingPLU
	
	# Close the file
	doneReading:
		li   $v0, 16       # system call for close file
		move $a0, $t9      # file descriptor to close
		syscall            # close file
	
		jr $ra

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
	
clearBuffer:
	la $t0, buffer		# t3 <- &buffer
	li $t1, 0		# t0 <- i = 0
	clearLoop:		# for(i=0,i<256,i++)
		slti $t2, $t1, 256			# if(i<256) t1 <- 1 else t1 <- 0
		beq $t2, $zero, endClearLoop		# if(t1==0) ovvero se(i>=256) end loop...
		sll $t2, $t1, 2				# t1 <- offset(i) = i * 4
		add $t4, $t0, $t2			# t4 <- &buffer[i] = &buffer + offset(i)
		sb $zero, 0($t4)			# buffer_str[i] <- zero
		addi $t1, $t1, 1			# i++
	j clearLoop
	
	endClearLoop:
	jr $ra

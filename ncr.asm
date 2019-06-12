.data  
	plufile: .asciiz "plu.dat"
	buffer: .space 32
	lineBreak: .asciiz "\n"
	articoli: .word 0
	articoli_n: .word 0
	emptyPlu: .asciiz "\n\nANAGRAFICA VUOTA\n\n"
.text
################################################
main:	
	jal loadPLU
	#jal articoli_print
	
	li $v0, 10
	syscall

########## LOAD PARAMS ##################
loadPLU:
	# PLU file open
	li $v0, 13		# Open file = 13
	la $a0, plufile   	# file name
	li $a1, 0        	# 0 = Reading 1 = Write
	syscall
	move $s0, $v0      	# Salvo in $s0 il file descriptor
	readingPLU:
		li $v0, 14       	# Reading from file = 14
		move $a0, $s0      	# NON TOCCARE $s0 dove c'è il descriptor del file
		la $a1, buffer   	# Indirizzo del buffer
		li $a2, 32		# Lunghezza riga da leggere
		syscall            	
		
		beq $v0, $zero, doneReading	# Check che controlla quando termina la lettura
        	slt $t0, $v0, $zero
        	beq $t0, 1, doneReading
        	
        	la $a0, buffer		# SCAN EAN
        	li $a1, 0		# Start = 0
        	li $a2, 13		# End = 13
        	addi $sp, $sp, -4
        	sw $ra, 0($sp)
        	jal substring
        	lw $ra, 0($sp)
        	addi $sp, $sp, 4
		move $s1, $v0		# Salvo in $s1 la stringa restituita da substring
		
		la $a0, buffer		# SCAN PRICE
        	li $a1, 25		# Start = 25
        	li $a2, 5		# End = 5
        	addi $sp, $sp, -4
        	sw $ra, 0($sp)
        	jal substring
        	lw $ra, 0($sp)
        	addi $sp, $sp, 4
        	move $s3, $v0		# Salvo in $s2 la stringa restituita da substring
		     	       	       	        	       	        	       	        	       	        	       	        	     	        	       	        	       	        	       	        	       	        	       	        	
		la $a0, buffer		# SCAN TEXT
        	li $a1, 13		# Start = 13
        	li $a2, 12		# End = 12
        	addi $sp, $sp, -4
        	sw $ra, 0($sp)
        	jal substring
        	lw $ra, 0($sp)
        	addi $sp, $sp, 4
        	move $s2, $v0		# Salvo in $s3 la stringa restituita da substring

		move $a0, $s1
		move $a1, $s2
		move $a2, $s3
		
		addi $sp, $sp, -4
        	sw $ra, 0($sp)
        	jal articoli_push
        	lw $ra, 0($sp)
        	addi $sp, $sp, 4

		j readingPLU
	
	# Close the file
	doneReading:
		li   $v0, 16       # system call for close file
		move $a0, $t9      # file descriptor to close
		syscall            # close file
	
		jr $ra
		
############## METODI USEFULL #####################
substring:			# SUBSTRING
	addi $sp, $sp, -4
	sw $a0, 0($sp)		# Salvo la stringa nello stack
	addi $sp, $sp, -4
	sw $a1, 0($sp)		# Salvo lo start nello stack
	addi $sp, $sp, -4
	sw $a1, 0($sp)		# Salvo l'end nello stack
	
	li $v0, 9		# Alloco spazio per leggere i vari caratteri
	move $a0, $a2		# $a2 = n_byte (coincide all'end della substring) 
	syscall
	
        lw $a1, 0($sp)		# Ripristino l'end dallo stack
	addi $sp, $sp, 4
        lw $a1, 0($sp)		# Ripristino lo start dallo stack
	addi $sp, $sp, 4
        lw $a0, 0($sp)		# Ripristino la stringa dallo stack
	addi $sp, $sp, 4
	
	li $t0, 0
	move $t1, $v0
	add $a0, $a0, $a1	# Aggiungo l'offset (lo start) alla stringa passata
	SCAN:	
	lb $t2, 0($a0)		# Leggo il primo carattere 
	sb $t2, 0($t1)		# Salvo in memoria il carattere
	addi $t1, $t1, 1	# Incremento di uno il puntatore dello spazio in memoria
	addi $a0, $a0, 1	# Incremento di uno il puntatore della stringa
	addi $t0, $t0, 1	# Incremento di uno il contatore dei caratteri letti
	bne $t0, $a2, SCAN	# Se il numero di caratteri letti è uguale all'end del substring esco
		
	jr $ra

clearBuffer:			#CLEAR BUFFER
	li $t0, 0		# t0 <- i = 0
	clearLoop:		# for(i=0,i<x,i++)
		slt $t1, $t0, $a1			# if(i<x) t1 <- 1 else t1 <- 0
		beq $t1, $zero, endClearLoop		# if(t1==0) ovvero se(i>=x) end loop
		sb $zero, 0($a0)			# buffer[i] <- zero
		addi $a0, $a0, 1			# t1 <- &buffer[i] = &buffer + offset(i)
		addi $t0, $t0, 1			# i++
		j clearLoop
	endClearLoop:
	jr $ra
######### METODI STACK ##################
articoli_push:
	move $t0, $a0 		# EAN
	move $t1, $a1		# TEXT
	move $t2, $a2		# PRIZE
	
	la $t3, articoli	# Mi carico posizione dello stack + indice stack
	lw $t4, 0($t3)

	li $v0, 9		# Creo spazio [9]
	li $a0, 16		# 4 parole * 4Byte
	syscall
	
	li $t7, 13
	LOOP_EAN:
	sw $t0, 0($v0)		# Salvo i valori nello spazio creato
	sw $t1, 4($v0)		
	sw $t2, 8($v0)
	sw $t4, 12($v0)		# next = *old_stack
	
	la $t5, articoli_n
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
		lw $t4, 4($t2)
		lw $t5, 8($t2)
		la $t1, 12($t2)
		
		li $v0, 4
		move $a0, $t4
		syscall
		
		li $v0, 4
		la $a0, lineBreak
		syscall
		
		subi $t0, $t0, 1
		bgt $t0, $zero, PRINT
	jr $ra
	
EMPTY:
	li $v0, 4
	la $a0, emptyPlu
	syscall
	
	li $v0, 10
	syscall
